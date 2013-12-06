require 'core_ext/hash/slice'
require 'core_ext/module/prepend_to'

module Travis
  module Exceptions
    module Handling
      def rescues(name, options = {})
        prepend_to(name) do |object, method, *args, &block|
          begin
            method.call(*args, &block)
          rescue options[:from] || Exception => e
            Exceptions.handle(e, options.slice(:backtrace))
          end
        end unless Travis.env == 'test'
      end
    end
  end
end

