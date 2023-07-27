# https://github.com/guilleiguaran/rails/blob/735a9ed6358b5b8d3d74cd140cad086bf5663029/activesupport/lib/active_support/core_ext/securerandom.rb
# frozen_string_literal: true

require 'securerandom'

module SecureRandom
  unless respond_to?(:uuid)
    def self.uuid
      ary = random_bytes(16).unpack('NnnnnN')
      ary[2] = (ary[2] & 0x0fff) | 0x4000
      ary[3] = (ary[3] & 0x3fff) | 0x8000
      '%08x-%04x-%04x-%04x-%04x%08x' % ary
    end
  end
end
