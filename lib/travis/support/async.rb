require 'thread'
require 'core_ext/module/prepend_to'

module Travis
  module Async
    autoload :Sidekiq,  'travis/support/async/sidekiq'
    autoload :Threaded, 'travis/support/async/threaded'

    class << self
      attr_writer :enabled

      def enabled?
        !!@enabled
      end

      def run(target, method, options, *args, &block)
        if enabled?
          options[:queue] ||= target.is_a?(Module) ? target.name : target.class.name
          strategy = strategy(options.delete(:use))
          puts "Enqueueing target: #{target}, method: #{method} to #{options[:queue]} using #{strategy}" if options[:debug] || Travis.respond_to?(:config) && Travis.config.log_level == :debug
          strategy.run(target, method, options, *args, &block)
        elsif method.is_a?(Method)
          method.call(*args, &block)
        else
          target.send(method, *args, &block)
        end
      rescue Exception => e
        puts "Exception caught in #{name}.call. Exceptions should be caught in client code"
        puts e.message, e.backtrace
      end

      def strategy(name)
        const_get(camelize(name || 'threaded'))
      end

      def camelize(string)
        string.to_s.gsub(/^.{1}|_.{1}/) { |char| char.gsub('_', '').upcase }
      end
    end

    def async(name, options = {})
      prepend_to name do |target, method, *args, &block|
        Async.run(target, method, options, *args, &block)
      end
    end
  end
end

