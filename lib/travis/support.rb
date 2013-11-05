require 'securerandom'
require 'core_ext/securerandom'

module Travis
  require 'travis/support/assertions'
  require 'travis/support/async'
  require 'travis/support/chunkifier'
  require 'travis/support/database'
  require 'travis/support/exceptions'
  require 'travis/support/helpers'
  require 'travis/support/instrumentation'
  require 'travis/support/log_subscriber'
  require 'travis/support/logging'
  require 'travis/support/memory'
  require 'travis/support/new_relic'
  require 'travis/support/retryable'

  class << self
    def env
     ENV['ENV'] || ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
    end

    def logger
      @logger ||= Logging.configure(Logger.new(STDOUT))
    end

    def logger=(logger)
      @logger = Logging.configure(logger)
    end

    def uuid= (uuid)
      Thread.current[:uuid] = uuid
    end

    def uuid
      Thread.current[:uuid] ||= SecureRandom.uuid
    end
  end
end
