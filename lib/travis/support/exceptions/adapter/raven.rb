require 'raven'

module Travis
  module Exceptions
    module Adapter
      class Raven
        attr_reader :logger

        def initialize(config, logger, options = {})
          @logger = logger

          ::Raven.configure do |c|
            c.dsn = config.sentry.dsn
            c.ssl = config.ssl if config.ssl
            c.logger = logger
            c.current_environment = options[:env]
          end
        end

        def handle(error, metadata = {}, options = {})
          logger.error(message_for(error))
          ::Raven.capture_exception(error, metadata)
        end

        private

          def message_for(error)
            lines = ["Error: #{error.message}"]
            lines += error.backtrace ? error.backtrace : [] if logger.level == ::Logger::DEBUG
            lines.join("\n")
          end
      end
    end
  end
end
