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
      instrument_method(name, options)
      subscribe_method(name, options)
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

      def instrument_method(name, options)
        wrapped = "#{name}_without_instrumentation"

        event    = self.name.underscore.gsub('/', '.')
        event << '.#{' << options[:scope].to_s << '}' if options[:scope]
        event << '.' << name.to_s

        rename_method(name, wrapped)
        class_eval instrumentation_template(name, event, wrapped)
      end

      def rename_method(old_name, new_name)
        alias_method(new_name, old_name)
        remove_method(old_name)
        private(new_name)
      end

      def instrumentation_template(name, event, wrapped)
        as = 'ActiveSupport::Notifications.%s("%s:%s", :target => self, :args => args)'
        <<-RUBY
          def #{name}(*args, &block)
            #{as % [ :publish, event, 'received']}
            result = #{as % [ :instrument, event, 'call']} { #{wrapped}(*args, &block) }
            #{as % [ :publish, event, 'completed']}
            result
          rescue Exception => e
            #{as % [ :publish, event, 'failed']}
            raise
          end
        RUBY
      end
  end
end
