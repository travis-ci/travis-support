# frozen_string_literal: true

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

        def enqueue(error, options = {})
          queue.push([error, options])
        end

        def adapter
          Travis.config.sentry.dsn ? Adapter::Sentry : Adapter::Logger
        rescue LoadError => e
          Travis.logger.error 'Could not load sentry, falling back to logger for exception reporting'
          Adapter::Logger.new
        end
      end

      class_attribute :queue
      self.queue = Queue.new

      attr_accessor :thread

      def run
        @thread = Thread.new(&method(:error_loop))
      end

      def error_loop
        loop(&method(:pop))
      end

      def pop
        handle(*queue.pop)
      rescue StandardError => e
      end

      def handle(error, options = {})
        adapter.handle(error, { extra: metadata_for(error) }, options)
      rescue Exception => e
        puts '---- FAILSAFE ----'
        puts "Error while handling exception: #{e.message}"
        puts e.backtrace
        puts '------------------'
      end

      def adapter
        @adapter ||= self.class.adapter.new(Travis.config, Travis.logger, env: Travis.env)
      end

      def metadata_for(error)
        error.respond_to?(:metadata) ? error.metadata : {}
      end
    end
  end
end
