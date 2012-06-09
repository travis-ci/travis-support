require 'active_support/notifications'
require 'active_support/core_ext/string/inflections'
require 'securerandom' # wat
require 'core_ext/module/prepend_to'
require 'metriks'
require 'metriks/reporter/logger'

module Travis
  module Instrumentation
    class << self
      def setup
        Metriks::Reporter::Logger.new.start
      end

      def call(event, started_at, finished_at, hash, args)
        event = event.split('.').reverse.join('.')
        Metriks.timer(event).update(finished_at - started_at)
      end

      def track(event, args)
        event = event.split('.').reverse.join('.')
        Metriks.meter(event).mark
      end
    end

    def instrument(name, options = {})
      prepend_to(name) do |object, method, *args, &block|
        instrument_method(name, object, options, method, args, block)
      end

      # todo how to ask as::notifications if we're subscribed?
      subscribe_method(name, options) unless @subscribed
    end

    private

      def subscribe_method(name, options)
        namespace = self.name.underscore.split('/').reverse.join('.')
        ActiveSupport::Notifications.subscribe(/^#{name}\.(.+\.)?#{namespace}$/, &Instrumentation.method(:call))
        ActiveSupport::Notifications.subscribe(/^.+\.#{name}\.(.+\.)?#{namespace}$/, &Instrumentation.method(:track)) if options[:track]
        @subscribed = true
      end

      def instrument_method(name, object, options, method, args, block)
        namespace = object.class.name.underscore.split('/').reverse
        scope = options[:scope] ? object.send(options[:scope]) : nil
        event = [name, scope, *namespace].compact.join('.')

        ActiveSupport::Notifications.instrument(event, :target => object, :args => args) do
          if options[:track]
            track_method(event, object, args) do
              method.call(*args, &block)
            end
          else
            method.call(*args, &block)
          end
        end
      end

      def track_method(name, object, args)
        begin
          track_event(name, :received, object, args)
          result = yield
          track_event(name, :completed, object, args)
          result
        rescue Exception => e
          track_event(name, :failed, object, args)
          raise
        end
      end

      def track_event(name, event, object, args)
        event = [event, name].join('.')
        ActiveSupport::Notifications.publish(event, :target => object, :args => args)
      end
  end
end
