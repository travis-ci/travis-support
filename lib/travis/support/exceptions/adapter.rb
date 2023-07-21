module Travis
  module Exceptions
    module Adapter
      autoload :Sentry,  'travis/support/exceptions/adapter/sentry'
      autoload :Logger, 'travis/support/exceptions/adapter/logger'
    end
  end
end

