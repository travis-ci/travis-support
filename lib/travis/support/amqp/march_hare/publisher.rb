# frozen_string_literal: true

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
        @name = @options.delete(:name) || ''
        @type = @options.delete(:type) || 'direct'
      end

      def publish(data, options = {})
        data = MultiJson.encode(data)
        defaults = { routing_key:, properties: { message_id: rand(100_000_000_000).to_s } }
        retrying do
          exchange.publish(data, deep_merge(defaults, options))
        end
      end

      protected

      def exchange
        @exchange ||= self.class.channel.exchange(name, durable: true, auto_delete: false, type:)
      end

      def retrying(&block)
        retries ||= 0
        block.call
      rescue Exception, java.lang.Throwable => e
        Travis.logger.error("Exception while trying to publish an AMQP message:\n#{e.message}")
        retries += 1
        raise e unless retries < 5

        sleep 1
        retry
      end

      def deep_merge(hash, other)
        hash.merge(other, &(merger = proc { |_key, v1, v2|
                              v1.is_a?(Hash) && v2.is_a?(Hash) ? v1.merge(v2, &merger) : v2
                            }))
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

      def channel
        @channel ||= Amqp.connection.create_channel
      end

      def exchange
        @exchange ||= channel.exchange(name, type: :fanout)
      end
    end
  end
end
