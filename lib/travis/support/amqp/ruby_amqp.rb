require 'amqp'
require 'amqp/utilities/event_loop_helper'

module Travis
  module Amqp
    require 'travis/support/amqp/ruby_amqp/consumer'
    require 'travis/support/amqp/ruby_amqp/publisher'

    class << self
      def config
        @config
      end

      def config=(config)
        @config = config
      end

      def connected?
        !!@connection
      end

      def connection
        @connection ||= begin
          AMQP::Utilities::EventLoopHelper.run
          AMQP.start(config) do |conn, open_ok|
            conn.on_tcp_connection_loss do |conn, settings|
              puts "[network failure] Trying to reconnect..."
              conn.reconnect(false, 2)
            end
          end
        end
      end
      alias :connect :connection

      def disconnect
        if connection
          connection.close if connection.open?
          @connection = nil
        end
      end
    end
  end
end
