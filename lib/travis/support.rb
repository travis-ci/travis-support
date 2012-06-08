module Travis
  autoload :Amqp,            'travis/support/amqp'
  autoload :Assertions,      'travis/support/assertions'
  autoload :Async,           'travis/support/async'
  autoload :Database,        'travis/database'
  autoload :Exceptions,      'travis/support/exceptions'
  autoload :Instrumentation, 'travis/support/instrumentation'
  autoload :Logging,         'travis/support/logging'
  autoload :Retryable,       'travis/support/retryable'

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
  end
end
