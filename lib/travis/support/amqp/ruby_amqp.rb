# frozen_string_literal: true

require 'amqp'
require 'amqp/utilities/event_loop_helper'

module Travis
  module Amqp
    require 'travis/support/amqp/ruby_amqp/consumer'
    require 'travis/support/amqp/ruby_amqp/publisher'

    class << self
      attr_accessor :config

      def connected?
        !!@connection
      end

      def connection
        @connection ||= begin
          AMQP::Utilities::EventLoopHelper.run
          AMQP.start(config) do |conn, _open_ok|
            conn.on_tcp_connection_loss do |conn, _settings|
              puts '[network failure] Trying to reconnect...'
              conn.reconnect(false, 2)
            end
          end
        end
      end
      alias connect connection

      def disconnect
        return unless connection

        connection.close if connection.open?
        @connection = nil
      end
    end
  end
end
