# frozen_string_literal: true

module Travis
  module Amqp
    class Consumer
      def initialize
        raise 'AMQP Bunny consumer is not available or recommended for use, consider using march_hare'
      end
    end
  end
end
