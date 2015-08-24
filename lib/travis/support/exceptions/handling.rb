require 'core_ext/hash/slice'
require 'core_ext/module/prepend_to'

module Travis
  module Exceptions
    module Handling
      def rescues(name, options = {})
        prepend_to(name) do |object, method, *args, &block|
          if Travis.env == 'test'
            method.call(*args, &block)
          else
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
end

