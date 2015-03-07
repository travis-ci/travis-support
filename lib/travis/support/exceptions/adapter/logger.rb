module Travis
  module Exceptions
    module Adapter
      class Logger
        attr_reader :logger

        def initialize(*)
          @logger = Travis.logger
        end

        def handle(error, metadata = {}, options = {})
          logger.error error.message
          logger.error metadata[:extra].map { |key, value| "#{key}: #{value}" } if metadata[:extra]
          logger.error error.backtrace unless options[:backtrace].is_a?(FalseClass)
        end
      end
    end
  end
end
