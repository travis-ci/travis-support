module Travis
  module Async
    module Threaded
      class Queue
        attr_reader :name
        attr_reader :items

        def initialize(name)
          @name  = name
          @items = ::Queue.new
          Thread.new { loop { work } }
        end

        def work
          @items.pop.call
        end

        def <<(item)
          @items.push(item)
        end
      end

      class << self
        def run(target, method, options, *args, &block)
          uuid = Travis.uuid
          queue(options[:queue]) << lambda { call(uuid, target, method, *args, &block) }
        end

        def call(uuid, target, method, *args, &block)
          Travis.uuid = uuid
          method.is_a?(Method) ? method.call(*args, &block) : target.send(method, *args, &block)
        rescue Exception => e
          puts "Exception caught in #{name}.call. Exceptions should be caught in client code"
          puts e.message, e.backtrace
        end

        def queue(name)
          queues[name || :default] ||= Queue.new(name)
        end

        def queues
          @queues ||= {}
        end
      end
    end
  end
end
