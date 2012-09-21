require 'thread'
require 'hubble'
require 'active_support/core_ext/class/attribute'

module Travis
  module Exceptions
    # A simple exception reporting queue that has a run loop in a separate
    # thread. Queued exceptions will be pushed to Hubble and logged.
    class Reporter
      class << self
        def start
          Reporter.new.run
        end

        def enqueue(error)
          queue.push(error)
        end
      end

      class_attribute :queue
      self.queue = Queue.new

      attr_accessor :thread

      def run
        if hubble?
          Hubble.setup
          Hubble.config['ssl'] = Travis.config.ssl
        end
        @thread = Thread.new &method(:error_loop)
      end

      def hubble?
        !!ENV['HUBBLE_ENV']
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
        Hubble.report(error, metadata_for(error)) if hubble?
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
        metadata = { 'env' => Travis.env, 'codename' => ENV['CODENAME'] }
        metadata.merge!(error.metadata) if error.respond_to?(:metadata)
        metadata
      end
    end
  end
end

