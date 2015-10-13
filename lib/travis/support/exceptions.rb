module Travis
  module Exceptions
    require 'travis/support/exceptions/adapter'
    require 'travis/support/exceptions/handling'
    require 'travis/support/exceptions/reporter'

    class << self
      def setup(config = nil)
        @config = config.to_h
        Exceptions::Reporter.start
      end

      def config
        puts 'Relying on Travis.config is deprecated: Call Travis::Exceptions.setup(config) instead.'
        @config || Travis.config
      end

      def handle(exception, options = {})
        Reporter.enqueue(exception, options)
      end
    end
  end
end

