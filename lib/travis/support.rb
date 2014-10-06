require 'securerandom'
require 'core_ext/securerandom'

module Travis
  require 'travis/support/assertions'
  require 'travis/support/async'
  require 'travis/support/chunkifier'
  require 'travis/support/exceptions'
  require 'travis/support/helpers'
  require 'travis/support/instrumentation'
  require 'travis/support/log_subscriber'
  require 'travis/support/logger'
  require 'travis/support/logging'
  require 'travis/support/metrics'
  if RUBY_PLATFORM == 'java'
    require 'travis/support/memory'
  end
  require 'travis/support/retryable'

  class << self
    def env
     ENV['ENV'] || ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
    end

    def logger
      @logger ||= Logger.configure(Logger.new(STDOUT))
    end

    def logger=(logger)
      @logger = Logger.configure(logger)
    end

    def uuid=(uuid)
      Thread.current[:uuid] = uuid
    end

    def uuid
      Thread.current[:uuid] ||= SecureRandom.uuid
    end
  end
end
