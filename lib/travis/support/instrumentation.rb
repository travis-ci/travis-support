require 'active_support/notifications'
require 'core_ext/module/prepend_to'
require 'metriks'

module Travis
  # Subscribes to the ActiveSupport::Notification API so we can use it for
  # logging and instruments calls to `notify` (i.e. logs events).
  module Instrumentation
    class << self
      def consume(event, started_at, finished_at, hash, args)
        Metriks.timer(event).update(finished_at - started_at)
      end
    end

    def instrument(name)
      event = self.name.underscore.split('/').reverse.join('.')

      prepend_to(name) do |object, method, *args, &block|
        ActiveSupport::Notifications.instrument(event, :target => object, :args => args) do
          method.call(*args, &block)
        end
      end

      ActiveSupport::Notifications.subscribe(/#{event}$/, &Instrumentation.method(:consume))
    end
  end
end

