require 'active_support/notifications'
require 'active_support/core_ext/string/inflections'
require 'securerandom' # wat
require 'core_ext/module/prepend_to'
require 'metriks'
require 'metriks/reporter/logger'

ActiveSupport::Notifications::Instrumenter.class_eval do
  def instrument(name, payload={})
    started = Time.now

    begin
      if name[0..5] == 'travis'
        payload[:result] = yield # add the result to the payload
      else
        yield
      end
    rescue Exception => e
      payload[:exception] = [e.class.name, e.message]
      raise e
    ensure
      @notifier.publish(name, started, Time.now, @id, payload)
    end
  end
end

module Travis
  module Instrumentation
    class << self
      def setup
        Metriks::Reporter::Logger.new.start
      end

      def track(event, *args)
        payload = args.pop
        started_at, finished_at, id = *args

        if started_at
          Metriks.timer(event).update(finished_at - started_at)
        else
          Metriks.meter(event).mark
        end
      end
    end

    def instrument(name, options = {})
      # prepend_to(name) do |object, method, *args, &block|
      #   instrument_method(name, object, options, method, args, block)
      # end
      # subscribe_method(name, options)
    end

    private

      def subscribed?(event)
        ActiveSupport::Notifications.notifier.listening?(event)
      end

      def subscribe_method(name, options)
        namespace = self.name.underscore.gsub('/', '.')
        event = /^#{namespace}\.(.+\.)?#{name}(:(received|call|completed|failed))?$/
        ActiveSupport::Notifications.subscribe(event, &Instrumentation.method(:track)) unless subscribed?(event)
      end

      def instrument_method(name, object, options, method, args, block)
        scope = options[:scope] ? object.send(options[:scope]) : nil
        namespace = object.class.name.underscore.split('/') << scope << name
        event = namespace.compact.join('.')

        track_method(event, object, args) do
          method.call(*args, &block)
        end
      end

      def track_method(name, object, args, &block)
        begin
          track_event(name, :received, object, args)
          result = ActiveSupport::Notifications.instrument([name, :call].join(':'), :target => object, :args => args, &block)
          track_event(name, :completed, object, args)
          result
        rescue Exception => e
          track_event(name, :failed, object, args)
          raise
        end
      end

      def track_event(name, event, object, args)
        ActiveSupport::Notifications.publish([name, event].join(':'), :target => object, :args => args)
      end
  end
end
