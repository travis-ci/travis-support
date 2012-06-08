require 'active_support/notifications'
require 'active_support/core_ext/string/inflections'
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

    def instrument(name, options = {})
      prepend_to(name) do |object, method, *args, &block|
        namespace = object.class.name.underscore.split('/').reverse
        scope = options[:scope] ? object.send(options[:scope]) : nil
        event = [name, scope, *namespace].compact.join('.')
        ActiveSupport::Notifications.instrument(event, :target => object, :args => args) do
          method.call(*args, &block)
        end
      end

      # TODO how to ask AS::Notifications if we're subscribed?
      unless @subscribed
        namespace = self.name.underscore.split('/').reverse.join('.')
        event = /^#{name}\.(.*\.)?#{namespace}$/
        ActiveSupport::Notifications.subscribe(event, &Instrumentation.method(:consume))
        @subscribed = true
      end
    end
  end
end
