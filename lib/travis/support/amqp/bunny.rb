module Travis
  module Amqp
    require 'travis/support/amqp/bunny/publisher'
    require 'travis/support/amqp/bunny/consumer'

    class << self
      def setup(config)
        self.send(:config=, config.to_h, false)
      end

      def config
        @config
      end

      def config=(config, deprecated = true)
        puts 'Calling Travis::Amqp.config= is deprecated. Call Travis::Amqp.setup(config) instead.' if deprecated

        config = config.dup
        config[:user] = config.delete(:username) if config[:username]
        config[:pass] = config.delete(:password) if config[:password]
        if config.key?(:tls)
          config[:ssl]  = true
          config[:tls]  = true
        end
        @config = config
      end

      def connected?
        !!@connection
      end

      def connection
        @connection ||=  begin
          require 'bunny'
          bunny = Bunny.new(config, :spec => '09')
          bunny.start
          bunny
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
