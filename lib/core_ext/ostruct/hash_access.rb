# frozen_string_literal: true

require 'ostruct'

class OpenStruct
  def [](name)
    @table[name.to_sym]
  end

  def []=(name, value)
    @table[name.to_sym] = value
  end
end
