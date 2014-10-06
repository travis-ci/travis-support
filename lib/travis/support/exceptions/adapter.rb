module Travis
  module Exceptions
    module Adapter
      autoload :Raven,  'travis/support/exceptions/adapter/raven'
      autoload :Logger, 'travis/support/exceptions/adapter/logger'
    end
  end
end

