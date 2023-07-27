# frozen_string_literal: true

require 'march_hare'

module Travis
  module Amqp
    require 'travis/support/amqp/march_hare/consumer'
    require 'travis/support/amqp/march_hare/publisher'

    class << self
      def config
        @config ||= {}
      end

      attr_writer :config

      def connected?
        !!@connection
      end

      def connection
        @connection ||= MarchHare.connect(config)
      end
      alias connect connection

      def disconnect
        return unless connection

        connection.close if connection.isOpen
        @connection = nil
      end
    end
  end
end
