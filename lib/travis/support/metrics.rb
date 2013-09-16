require 'metriks'

module Travis
  module Metrics
    METRICS_VERSION = 'v1'

    class << self
      def setup(reporter = nil)
        reporter ||= Travis.config.metrics.reporter
        if reporter
          Travis.logger.info("Starting metriks reporter #{reporter}.")
          require "metriks/reporter/#{reporter}"
          @reporter = Metriks::Reporter.const_get(reporter.camelize).new.start
        else
          Travis.logger.info('No metriks reporter configured.')
        end
      end

      def started?
        !!@reporter
      end

      def meter(event, options = {})
        return if !started? || options[:level] == :debug

        event = "#{METRICS_VERSION}.#{event}"
        started_at, finished_at = options[:started_at], options[:finished_at]

        if finished_at
          Metriks.timer(event).update(finished_at - started_at)
        else
          Metriks.meter(event).mark
        end
      end
    end
  end
end
