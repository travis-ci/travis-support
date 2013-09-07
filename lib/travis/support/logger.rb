require 'logger'

module Travis
  class Logger < ::Logger
    autoload :Format, 'travis/support/logger/format'

    class << self
      def configure(logger)
        logger.tap do
          logger.formatter = Format.new(config && config[:logger])
          logger.level = Logger.const_get(log_level.to_s.upcase)
        end
      end

      def log_level
        config && config.log_level || :debug
      end

      def config
        if defined?(Travis::Worker)
          Travis::Worker.config
        elsif Travis.respond_to?(:config)
          Travis.config
        end
      end
    end

    [:fatal, :error, :warn, :info, :debug].each do |level|
      define_method(level) do |msg, options = {}|
        super(msg.chomp.split("\n").map { |line| prepend_header(line, options) }.join("\n") + "\n")
      end
    end

    def wrap(type, name, args, options = {})
      send(type || :info, prepend_header("about to #{name}#{format_arguments(args)}", options)) unless options[:only] == :after
      result = yield
      send(type || :debug, prepend_header("done: #{name}", options)) unless options[:only] == :before
      result
    end

    private

      def prepend_header(line, options = {})
        if options[:log_header]
          "[#{options[:log_header]}] #{line}"
        else
          line
        end
      end

      def format_arguments(args)
        args.empty? ? '' : "(#{args.map { |arg| format_argument(arg).inspect }.join(', ')})"
      end

      def format_argument(arg)
        if arg.is_a?(Hash) && arg.key?(:log) && arg[:log].size > 80
          arg = arg.dup
          arg[:log] = "#{arg[:log][0..80]} ..."
        end
        arg
      end
  end
end
