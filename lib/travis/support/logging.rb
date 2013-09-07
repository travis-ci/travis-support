require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/module/aliasing'
require 'logger'

module Travis
  module Logging
    require 'travis/support/logging/format'

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def log_header(&block)
        block ? @log_header = block : @log_header
      end

      def log(name, options = {})
        define_method(:"#{name}_with_log") do |*args, &block|
          options[:log_header] ||= self.log_header
          Travis.logger.wrap(options[:as], name, options[:params].is_a?(FalseClass) ? [] : args, options) do
            send(:"#{name}_without_log", *args, &block)
          end
        end
        alias_method_chain name, 'log'
      end
    end

    delegate :logger, :to => Travis

    [:fatal, :error, :warn, :info, :debug].each do |level|
      define_method(level) do |*args|
        message, options = *args
        options ||= {}
        options[:log_header] ||= self.log_header
        logger.send(level, message, options)
      end
    end

    def log_exception(exception)
      message = "#{exception.class.name}: #{exception.message}\n"
      message << exception.backtrace.join("\n") if exception.backtrace
      logger.error(message, log_header: log_header)
    rescue Exception => e
      puts '--- FATAL ---'
      puts 'an exception occured while logging an exception'
      puts e.message, e.backtrace
      puts exception.message, exception.backtrace
    end

    def log_header
      self.class.log_header ? instance_eval(&self.class.log_header) : self.class.name.split('::').last.downcase
    end
  end
end