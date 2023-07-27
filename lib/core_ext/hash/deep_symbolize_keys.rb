# frozen_string_literal: true

class Hash
  unless Hash.method_defined?(:deep_symbolize_keys)
    def deep_symbolize_keys
      each_with_object({}) do |(key, value), result|
        result[begin
          key.to_sym
        rescue StandardError
          key
        end || key] = case value
                      when Array
                        value.map do |value|
                          value.is_a?(Hash) ? value.deep_symbolize_keys : value
                        end
                      when Hash
                        value.deep_symbolize_keys
                      else
                        value
                      end
      end
    end
  end

  unless Hash.method_defined?(:deep_symbolize_keys!)
    def deep_symbolize_keys!
      replace(deep_symbolize_keys)
    end
  end
end
