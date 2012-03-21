require 'bunny'

module Travis
  module Amqp
    autoload :Consumer,  'travis/support/amqp/ruby_amqp/consumer'
    autoload :Publisher, 'travis/support/amqp/ruby_amqp/publisher'

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
        @connection = Bunny.start(config)
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
