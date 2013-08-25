require 'active_support/notifications'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/logger'
require 'securerandom' # wat
require 'metriks'
require 'metriks/reporter/logger'

module Travis
  module Instrumentation
    METRICS_VERSION = 'v1'

    class << self
      def setup
        Travis.logger.info("Starting metriks reporter logger.")
        Metriks::Reporter::Logger.new.start
      end

      def meter(event, options = {})
        return if options[:level] == :debug
        event = "#{METRICS_VERSION}.#{event}"
        started_at, finished_at = options[:started_at], options[:finished_at]

        if finished_at
          Metriks.timer(event).update(finished_at - started_at)
        else
          Metriks.meter(event).mark
        end
      end
    end

    def instrumentation_key=(instrumentation_key)
      @@instrumentation_key = instrumentation_key
    end

    def instrumentation_key
      @@instrumentation_key ||= name.underscore.gsub('/', '.')
    end

    def instrument(name, options = {})
      wrapped = "#{name}_without_instrumentation"
      alias_method(wrapped, name)
      remove_method(name)
      private(wrapped)
      class_eval instrumentation_template(name, options[:scope], wrapped, options[:level] || :info)
    end

    private

      def instrumentation_template(name, scope, wrapped, level)
        options = ':target => self, :args => args, :started_at => started_at, :level => ' + level.inspect
        meter   = 'Travis::Instrumentation.meter "#{event}:%s", ' + options
        publish = 'ActiveSupport::Notifications.publish "#{event}:%s", ' + options
        <<-RUBY
          def #{name}(*args, &block)
            started_at = Time.now.to_f
            event = self.class.instrumentation_key.dup #{"<< '.' << #{scope}" if scope} << ".#{name}"
            #{publish % 'received'}
            result = #{wrapped}(*args, &block)
            #{meter   % 'completed'}, :finished_at => Time.now.to_f, :result => result
            #{publish % 'completed'}, :finished_at => Time.now.to_f, :result => result
            result
          rescue Exception => e
            #{meter   % 'failed'}, :exception => [e.class.name, e.message]
            #{publish % 'failed'}, :exception => [e.class.name, e.message]
            raise
          end
        RUBY
      end
  end
end
