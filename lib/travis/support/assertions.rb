require 'active_support/core_ext/module/aliasing'

module Travis
  class AssertionFailed < RuntimeError
    attr_reader :object, :method

    def initialize(object = nil, method = nil, message = nil)
      @object = object
      @method = method
      @message = message
    end

    def message
      @message ? @message : "#{object.inspect}##{method} did not return true."
    end
  end

  module Assertions
    def assert(name, message = nil)
      define_method(:"#{name}_with_assert") do |*args, &block|
        send(:"#{name}_without_assert", *args, &block).tap do |result|
          raise Travis::AssertionFailed.new(self, name, message) unless result
        end
      end
      alias_method_chain name, 'assert'
    end
  end
end
