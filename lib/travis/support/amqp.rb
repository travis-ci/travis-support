amqp = RUBY_PLATFORM == 'java' ? 'march_hare' : 'bunny'
require "travis/support/amqp/#{amqp}"

Travis::Amqp::Consumer.class_eval do
  class << self
    def configure
      new('builds.configure')
    end

    def builds
      new(Travis::Worker.config.queue)
    end

    def jobs(routing_key, options = {})
      options = { exchange: { name: 'reporting' } }.deep_merge(options)
      new("reporting.jobs.#{routing_key}", options)
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
      new('builds.configure', :auto_recovery => true)
    end

    def builds(routing_key)
      new(routing_key)
    end

    def jobs(routing_key, options = {})
      options = { :type => 'topic', :name => 'reporting' }.update(options)
      new("reporting.jobs.#{routing_key}", options)
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
