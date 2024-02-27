# frozen_string_literal: true

unless {}.respond_to?(:compact)
  class Hash
    def compact
      dup.compact!
    end

    def compact!
      keys.each do |key|
        delete(key) if self[key].nil?
      end
      self
    end
  end
end
