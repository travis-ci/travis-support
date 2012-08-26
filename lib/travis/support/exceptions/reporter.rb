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
        Hubble.setup if hubble?
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
        Travis.logger.error("Error: #{error.message}\n#{error.backtrace ? error.backtrace.join("\n") : ''}")
        Hubble.report(error, metadata_for(error)) if hubble?
      rescue Exception => e
        puts '---- FAILSAFE ----'
        puts "Error while handling exception: #{e.message}"
        puts e.backtrace
        puts '------------------'
      end

      def message_for(error)
        lines = ["Error: #{error.message}"]
        lines += error.backtrace ? error.backtrace : []
        lines.join("\n")
      end

      def metadata_for(error)
        metadata = { 'env' => Travis.env }
        # TODO simply ask the exception for metadata and merge it
        metadata['payload']  = error.payload if error.respond_to?(:payload)
        metadata['event']    = error.event if error.respond_to?(:event)
        metadata['codename'] = ENV['CODENAME'] if ENV.key?('CODENAME')
        metadata
      end
    end
  end
end

