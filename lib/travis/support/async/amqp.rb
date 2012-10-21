module Travis
  module Async
    module Amqp
      class << self
        def run(target, method, options, *args)
          type, data, options = *args
          publisher.publish(:type => type, :data => data, :options => options)
        end

        def publisher(queue)
          Travis::Amqp::Publisher.new(('tasks'))
        end
      end
    end
  end
end

