require 'newrelic_rpm'
require 'core_ext/module/prepend_to'

module Travis
  module NewRelic
    class << self
      def start
        puts "Starting New Relic with env: #{Travis.env}"
        ::NewRelic::Agent.manual_start(:env => Travis.env)
        @started = true
      rescue Exception => e
        puts 'New Relic Agent refused to start!', e.message, e.backtrace
      end

      def started?
        !!@started
      end

      def proxy
        @proxy ||= Class.new do
          include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
        end.new
      end

      def trace(object, name, options, &block)
        if started?
          options = options.merge(:class_name => object.class.name, :name => name.to_s)
          proxy.perform_action_with_newrelic_trace(options, &block)
        else
          yield
        end
      end
    end

    def new_relic(*names)
      options = names.last.is_a?(Hash) ? names.pop : {}
      names.each do |name|
        prepend_to(name) do |object, method, *args, &block|
          NewRelic.trace(object, name, options) do
            method.call(*args, &block)
          end
        end
      end
    end
  end
end
