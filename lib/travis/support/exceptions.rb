module Travis
  module Exceptions
	require 'travis/support/exceptions/adapter'
    require 'travis/support/exceptions/handling'
    require 'travis/support/exceptions/reporter'

    class << self
      def handle(exception)
        Reporter.enqueue(exception)
      end
    end
  end
end

