# frozen_string_literal: true

require 'core_ext/hash/slice'
require 'core_ext/module/prepend_to'

module Travis
  module Exceptions
    module Handling
      def rescues(name, options = {})
        return if Travis.env == 'test'

        prepend_to(name) do |_object, method, *args, &block|
          begin
            method.call(*args, &block)
          rescue options[:from] || Exception => e
            Exceptions.handle(e, options.slice(:backtrace))
            raise if options[:raise] && Array(options[:raise]).include?(e.class)
          end
        end
      end
    end
  end
end
