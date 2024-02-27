# frozen_string_literal: true

require 'sentry-ruby'

module Travis
  module Exceptions
    module Adapter
      class Sentry
        attr_reader :logger

        def initialize(config, logger, options = {})
          @logger = logger

          ::Sentry.init do |c|
            c.dsn = config.sentry.dsn
            c.ssl = config.ssl if config.ssl
            c.logger = logger
            c.environment = options[:env]
          end
        end

        def handle(error, metadata = {}, _options = {})
          logger.error(message_for(error))
          ::Sentry.capture_exception(error, metadata)
        end

        private

        def message_for(error)
          lines = ["Error: #{error.message}"]
          lines += error.backtrace || [] if logger.level == ::Logger::DEBUG
          lines.join("\n")
        end
      end
    end
  end
end
