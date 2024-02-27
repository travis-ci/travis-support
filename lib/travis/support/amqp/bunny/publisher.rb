# frozen_string_literal: true

require 'multi_json'
require 'metriks'

module Travis
  module Amqp
    class Publisher
      attr_reader :name, :type, :routing_key, :options

      def initialize(routing_key, options = {})
        @routing_key = routing_key
        @options = options.dup
        @name = @options.delete(:name) || ''
        @type = @options.delete(:type) || 'direct'
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

      protected

      def default_data
        { key: routing_key, properties: { message_id: rand(100_000_000_000).to_s } }
      end

      def exchange
        @exchange ||= Amqp.connection.exchange(name, type: type.to_sym, durable: true, auto_delete: false)
      end

      def deep_merge(hash, other)
        hash.merge(other, &(merger = proc { |_key, v1, v2|
                              v1.is_a?(Hash) && v2.is_a?(Hash) ? v1.merge(v2, &merger) : v2
                            }))
      end

      def track_event(name = nil)
        meter_name = 'travis.amqp.messages.published'
        meter_name = "#{meter_name}.#{name}" if name
        Metriks.meter("#{meter_name}.#{routing_key}").mark
      end
    end

    class FanoutPublisher
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def publish(data, _options = {})
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
