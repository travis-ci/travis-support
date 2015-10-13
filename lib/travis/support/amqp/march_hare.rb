require 'march_hare'

module Travis
  module Amqp
    require 'travis/support/amqp/march_hare/consumer'
    require 'travis/support/amqp/march_hare/publisher'

    class << self
      def setup(config)
        self.send(:config=, config.to_h, false)
      end

      def config
        @config
      end

      def config=(config, deprecated = true)
        puts 'Calling Travis::Amqp.config= is deprecated. Call Travis::Amqp.setup(config) instead.' if deprecated
        @config = config
      end

      def connected?
        !!@connection
      end

      def connection
        @connection ||= MarchHare.connect(config)
      end
      alias :connect :connection

      def disconnect
        if connection
          connection.close if connection.isOpen
          @connection = nil
        end
      end
    end
  end
end
