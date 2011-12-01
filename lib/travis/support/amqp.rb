amqp = RUBY_PLATFORM == 'java' ? 'hot_bunnies' : 'ruby_amqp'
require "travis/support/amqp/#{amqp}"

Travis::Amqp::Consumer.class_eval do
  class << self
    def configure
      new('builds.configure')
    end

    def builds
      new(Travis::Worker.config.queue)
    end

    def jobs
      new('reporting.jobs')
    end

    def commands
      new("worker.commands.#{Travis::Worker.config.name}")
    end

    def replies
      new('replies') # TODO can't create a queue worker.replies?
    end

    def workers
      new('reporting.workers')
    end
  end
end

Travis::Amqp::Publisher.class_eval do
  class << self
    def configure
      new('builds.configure')
    end

    def builds(routing_key)
      new(routing_key)
    end

    def jobs
      new('reporting.jobs')
    end

    def commands
      new("worker.commands.#{Travis::Worker.config.name}")
    end

    def replies
      new('replies') # TODO can't create a queue worker.replies?
    end

    def workers
      new('reporting.workers')
    end
  end
end
