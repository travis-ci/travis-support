# frozen_string_literal: true

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
        config&.log_level || :debug
      end

      def config
        if defined?(Travis::Worker)
          Travis::Worker.config
        elsif Travis.respond_to?(:config)
          Travis.config
        end
      end
    end

    %i[fatal error warn info debug].each do |level|
      define_method(level) do |msg, options = {}|
        if msg.is_a?(Exception)
          exception = msg
          msg = "#{exception.class.name}: #{exception.message}"
          msg << "\n#{exception.backtrace.join("\n")}" if exception.backtrace
        end

        msg = msg.join("\n") if msg.respond_to?(:join)
        msg = msg.chomp.split("\n").map { |line| Travis::Logging.prepend_header(line, options) }.join("\n") + "\n"

        options.dup.tap do |opts|
          opts.delete(:progname)

          class << msg
            attr_reader :l2met_args
          end

          msg.instance_variable_set(:@l2met_args, opts)
        end

        super(msg)
      end
    end
  end
end
