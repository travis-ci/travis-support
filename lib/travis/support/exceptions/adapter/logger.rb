module Travis
  module Exceptions
    module Adapter
      class Logger
        def initialize(*)
        end

        def handle(error, metadata = {})
          Travis.logger.error error.message
          Travis.logger.error metadata[:extra].map { |key, value| "#{key}: #{value}" } if metadata[:extra]
          Travis.logger.error error.backtrace
        end
      end
    end
  end
end
