require 'thread'
require 'core_ext/module/prepend_to'

module Travis
  module Async
    autoload :Queue, 'travis/support/async/queue'

    class << self
      attr_writer :enabled

      def enabled?
        !!@enabled
      end

      def run(name = nil, &block)
        queue = self.queue(name)
        queue << block
        info "Async queue size: #{queue.size}" if respond_to?(:info)
      end

      def queue(name)
        queues[name || :default] ||= Queue.new(name)
      end

      def queues
        @queues ||= {}
      end
    end

    def async(name, options = {})
      prepend_to name do |object, method, *args, &block|
        if Async.enabled?
          uuid = Travis.uuid
          queue = options[:queue] || object.class.name
          Async.run(queue) do
            Travis.uuid = uuid
            method.call(*args, &block)
          end
        else
          method.call(*args, &block)
        end
      end
    end
  end
end

