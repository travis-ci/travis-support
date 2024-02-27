# frozen_string_literal: true

class Hash
  unless method_defined?(:slice)
    def slice(*keys)
      Hash[*keys.map { |key| [key, self[key]] if key?(key) }.compact.flatten]
    end
  end
end
