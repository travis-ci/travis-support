module Travis
  module Amqp
    class Consumer
      def initialize
        raise 'AMQP Bunny consumer is not avialable or recommended for use, consider using hot_bunnies'
      end
    end
  end
end
