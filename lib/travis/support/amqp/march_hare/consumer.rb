require 'hashr'
require 'travis/support/logging'

module Travis
  module Amqp
    class Consumer
      class << self
      end

      include Logging

      DEFAULTS = {
        :subscribe => { :ack => false, :blocking => false },
        :queue     => { :durable => true, :exclusive => false },
        :channel   => { :prefetch => 1 },
        :exchange  => { :name => nil, :routing_key => nil }
      }

      attr_reader :name, :options, :subscription

      def initialize(name, options = {})
        @name    = name
        @options = Hashr.new(DEFAULTS.deep_merge(options))
      end

      def subscribe(options = {}, &block)
        options = deep_merge(self.options.subscribe, options)
        debug "subscribing to #{name.inspect} with #{options.inspect}"
        @subscription = queue.subscribe(options, &block)
      end

      def unsubscribe
        debug "unsubscribing from #{name.inspect}"
        subscription.cancel if subscription.try(:active?)
      end

      protected

        def queue
          @queue ||= channel.queue(name, options.queue).tap do |queue|
            if options.exchange.name
              routing_key = options.exchange.routing_key || name
              queue.bind(options.exchange.name, :routing_key => routing_key)
            end
          end
        end

        def channel
          Amqp.connection.create_channel.tap do |channel|
            channel.prefetch = 1
          end
        end

        def deep_merge(hash, other)
          hash.merge(other, &(merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }))
        end
    end
  end
end
