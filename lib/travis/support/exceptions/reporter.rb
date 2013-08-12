require 'raven'
require 'thread'
require 'active_support/core_ext/class/attribute'

module Travis
  module Exceptions
    # A simple exception reporting queue that has a run loop in a separate
    # thread. Queued exceptions will be pushed to Sentry and logged.
    class Reporter
      class << self
        def start
          Reporter.new.run
        end

        def enqueue(error)
          queue.push(error)
        end

        def enabled?
          @enabled ||= begin
            require 'raven'
            !!Travis.config.sentry.dsn
          rescue LoadError => e
            false
          end
        end
      end

      class_attribute :queue
      self.queue = Queue.new

      attr_accessor :thread

      def run
        if enabled?
          ::Raven.configure do |config|
            config.dsn = Travis.config.sentry.dsn
            config.ssl = Travis.config.ssl if Travis.config.ssl
            config.logger = Travis.logger  if Travis.logger
            config.current_environment = Travis.env
          end
        end
        @thread = Thread.new &method(:error_loop)
      end

      def error_loop
        loop &method(:pop)
      end

      def pop
        handle(queue.pop)
      rescue => e
      end

      def handle(error)
        Travis.logger.error(message_for(error))
        options = { extra: metadata_for(error) }
        Raven.capture_exception(error, options) if enabled?
      rescue Exception => e
        puts '---- FAILSAFE ----'
        puts "Error while handling exception: #{e.message}"
        puts e.backtrace
        puts '------------------'
      end

      def message_for(error)
        lines = ["Error: #{error.message}"]
        lines += error.backtrace ? error.backtrace : [] if Travis.logger.level == Logger::DEBUG
        lines.join("\n")
      end

      def metadata_for(error)
        metadata = { }
        metadata.merge!(error.metadata) if error.respond_to?(:metadata)
        metadata
      end

      private

      def enabled?
        self.class.enabled?
      end
    end
  end
end

