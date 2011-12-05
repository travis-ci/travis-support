require 'thread'

class Async
  class Queue < Array
    attr_reader :name

    def initialize(name)
      @name = name
      Thread.new { loop { work } }
    end

    def work
      block = pop
      block.call if block
    rescue Exception => e
      puts e.message, e.backtrace
    end
  end

  class << self
    def run(name = nil, &block)
      queue(name) << block
    end

    def queue(name)
      queues[name || :default] ||= Queue.new(name)
    end

    def queues
      @queues ||= {}
    end
  end
end

Module.class.class_eval do
  def async(name, options = {})
    method = instance_method(name)
    define_method(name) do |*args, &block|
      Async.run(options[:queue]) { method.bind(self).call(*args, &block) }
    end
  end
end
