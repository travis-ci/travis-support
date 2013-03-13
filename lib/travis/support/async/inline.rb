module Travis
  module Async
    module Inline
      class << self
        def run(target, method, options, *args, &block)
          method.is_a?(Method) ? method.call(*args, &block) : target.send(method, *args, &block)
        rescue Exception => e
          puts "Exception caught in #{name}.call. Exceptions should be caught in client code"
          puts e.message, e.backtrace
        end
      end
    end
  end
end
