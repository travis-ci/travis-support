module Travis
  module Exceptions
    autoload :Handling, 'travis/support/exceptions/handling'
    autoload :Reporter, 'travis/support/exceptions/reporter'

    class << self
      def handle(exception)
        Reporter.enqueue(exception)
      end
    end
  end
end

