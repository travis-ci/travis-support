require 'thread'

module Travis
  module Async
    class Queue
      attr_reader :name
      attr_reader :items

      def initialize(name)
        @name  = name
        @items = ::Queue.new
        Thread.new { loop { work } }
      end

      def work
        @items.pop.call
      end

      def <<(item)
        @items.push(item)
      end
    end
  end
end

