require 'active_support/notifications'
require 'active_support/core_ext/string/inflections'
# require 'active_support/core_ext/logger' # gone in active_support?
require 'securerandom' # wat

module Travis
  module Instrumentation
    class << self
      def setup
        Travis.logger.info "[deprecated] Travis::Instrumentation.setup now does nothing. Call Travis::Metrics.setup instead."
      end

      def meter(event, options = {})
        Travis.logger.info "[deprecated] Call Travis::Metrics.meter instead of Travis::Instrumentation.meter."
        Travis::Metrics.meter(event, options)
      end
    end

    def instrumentation_key=(instrumentation_key)
      @instrumentation_key = instrumentation_key
    end

    def instrumentation_key
      @instrumentation_key ||= name.underscore.gsub('/', '.')
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
        meter   = 'Travis::Metrics.meter "#{event}:%s", ' + options
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
