require 'multi_json'

module Travis
  module Amqp
    class Publisher
      class << self
        def channel
          @channel ||= Amqp.connection.create_channel
        end
      end

      attr_reader :name, :type, :routing_key, :options

      def initialize(routing_key, options = {})
        @routing_key = routing_key
        @options = options.dup
        @name = @options.delete(:name) || ""
        @type = @options.delete(:type) || "direct"
      end

      def publish(data, options = {})
        data = MultiJson.encode(data)
        defaults = { :routing_key => routing_key, :properties => { :message_id => rand(100000000000).to_s } }
        exchange.publish(data, deep_merge(defaults, options))
      end

      protected

        def exchange
          @exchange ||= self.class.channel.exchange(name, :durable => true, :auto_delete => false, :type => type)
        end

        def deep_merge(hash, other)
          hash.merge(other, &(merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }))
        end
    end

    class FanoutPublisher
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def publish(data)
        data = MultiJson.encode(data)
        exchange.publish(data)
      rescue StandardError => e
        Exceptions.handle(e)
        nil
      end

      def exchange
        @exchange ||= self.class.channel.exchange(name, type: :fanout)
      end
    end
  end
end
