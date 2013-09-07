require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/module/aliasing'
require 'logger'

module Travis
  module Logging
    require 'travis/support/logging/format'

    ANSI = {
      :red    => 31,
      :green  => 32,
      :yellow => 33,
      :cyan   => 36
    }

    module ClassMethods
      def log_header(&block)
        block ? @log_header = block : @log_header
      end

      def log(name, options = {})
        define_method(:"#{name}_with_log") do |*args, &block|
          arguments = options[:params].is_a?(FalseClass) ? [] : args
          Logging.before(options[:as], self, name, arguments) unless options[:only] == :after
          send(:"#{name}_without_log", *args, &block).tap do |result|
            Logging.after(options[:as], self, name) unless options[:only] == :before
          end
        end
        alias_method_chain name, 'log'
      end
    end

    class << self
      def included(base)
        base.extend(ClassMethods)
      end

      delegate :logger, :to => Travis

      def configure(logger)
        logger.tap do
          logger.formatter = Format.new(config && config[:logger])
          logger.level = Logger.const_get(log_level.to_s.upcase)
        end
      end

      def before(type, *args)
        logger.send(type || :info, Format.before(*args))
      end

      def after(type, *args)
        logger.send(type || :debug, Format.after(*args))
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

    delegate :logger, :to => Travis

    [:fatal, :error, :warn, :info, :debug].each do |level|
      define_method(level) do |*args|
        if args.first.is_a?(Exception)
          exception, options = *args

          message = "#{exception.class.name}: #{exception.message}"
          if exception.backtrace
            message << "\n#{exception.backtrace.join("\n")}"
          end
        else
          message, options = *args
        end

        message.chomp.split("\n").each do |line|
          logger.send(level, Logging::Format.wrap(self, line, options || {}))
        end
      end
    end

    def log_exception(exception)
      logger.error(Logging::Format.wrap(self, "#{exception.class.name}: #{exception.message}"))
      exception.backtrace.each { |line| logger.error(Logging::Format.wrap(self, line)) } if exception.backtrace
    rescue Exception => e
      puts '--- FATAL ---'
      puts 'an exception occured while logging an exception'
      puts e.message, e.backtrace
      puts exception.message, exception.backtrace
    end

    def colorize(color, text)
      "\e[#{ANSI[color]}m#{text}\e[0m"
    end

    def log_header
      self.class.log_header ? instance_eval(&self.class.log_header) : self.class.name.split('::').last.downcase
    end
  end
end
