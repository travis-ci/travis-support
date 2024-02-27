# frozen_string_literal: true

module Travis
  module Async
    module Amqp
      class << self
        def run(_target, _method, options, *args)
          type, data, options = *args
          publisher.publish(type:, data:, options:)
        end

        def publisher(_queue)
          Travis::Amqp::Publisher.new('tasks')
        end
      end
    end
  end
end
