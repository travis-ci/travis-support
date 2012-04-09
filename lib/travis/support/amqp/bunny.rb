require 'bunny'

module Travis
  module Amqp
    autoload :Publisher, 'travis/support/amqp/bunny/publisher'
    autoload :Consumer,  'travis/support/amqp/bunny/consumer'

    class << self
      def config
        @config
      end

      def config=(config)
        config = config.dup
        config[:user] = config.delete(:username) if config[:username]
        config[:pass] = config.delete(:password) if config[:password]
        @config = config
      end

      def connected?
        !!@connection
      end

      def connection
        @connection ||= Bunny.new(config, :spec => '09').tap do |bunny|
          bunny.start
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
