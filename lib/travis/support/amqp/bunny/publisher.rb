require 'multi_json'
require 'metriks'

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
        #Bunny 1.7 needs to call create_channel each time
        @unique_channel = @options.delete(:unique_channel) || (Bunny::VERSION =~ /^(?:1\.(?:7|8|9|\d{2,})\.|[2-9]\d*\.)/)
      end

      def publish(data, options = {})
        data = MultiJson.encode(data)
        exchange.publish(data, deep_merge(default_data, options))
        track_event
      rescue StandardError => e
        Exceptions.handle(e)
        track_event(:failed)
        nil
      end

      #only for compatibility with march_hare
      def channel
        @channel ||= @unique_channel ? Amqp.connection.create_channel : self.class.channel
      end

      protected

        def default_data
          { :routing_key => routing_key , :properties => { :message_id => rand(100000000000).to_s } }
        end

        def exchange
          @exchange ||= channel.exchange(name, :type => type.to_sym, :durable => true, :auto_delete => false)
        end

        def deep_merge(hash, other)
          hash.merge(other, &(merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }))
        end

        def track_event(name = nil)
          meter_name = 'travis.amqp.messages.published'
          meter_name = "#{meter_name}.#{name.to_s}" if name
          Metriks.meter("#{meter_name}.#{routing_key}").mark
        end
    end

    class FanoutPublisher
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def publish(data, options = {})
        data = MultiJson.encode(data)
        exchange.publish(data)
      rescue StandardError => e
        Exceptions.handle(e)
        nil
      end

      def exchange
        @exchange ||= Amqp.connection.exchange(name, type: :fanout)
      end
    end
  end
end
