require 'metriks'

module Travis
  module Metrics
    module Reporter
      class << self
        def logger
          require 'metriks/reporter/logger'
          logger = Logger.new($stdout)
          logger.formatter = lambda do |severity, date, progname, message|
            "#{message}\n"
          end
          Metriks::Reporter::Logger.new(
            logger: logger,
            on_error: lambda { |error| puts error }
          )
        end

        def graphite
          require 'metriks/reporter/graphite'
          Metriks::Reporter::Graphite.new
        end
      end
    end

    METRICS_VERSION = 'v1'

    class << self
      attr_reader :reporter

      def setup(reporter = nil)
        reporter ||= Travis.config.metrics.reporter
        if reporter
          Travis.logger.info("Starting metriks reporter #{reporter}.")
          @reporter = Reporter.send(reporter)
          @reporter.start
        else
          Travis.logger.info('No metriks reporter configured.')
        end
      end

      def started?
        !!reporter
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
