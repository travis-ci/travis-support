# frozen_string_literal: true

class Array
  unless method_defined?(:flatten_once)
    def flatten_once
      # TODO: replace all calls to flatten_once with flatten(1)
      flatten(1)
    end
  end
end
