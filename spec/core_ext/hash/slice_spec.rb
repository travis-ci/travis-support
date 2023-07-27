# frozen_string_literal: true

require 'spec_helper'
require 'core_ext/hash/slice'

describe 'Hash#slice' do
  it 'returns a new hash containing the given keys' do
    hash = { foo: 'foo', bar: 'bar', baz: 'baz' }
    hash.slice(:foo, :bar).should == { foo: 'foo', bar: 'bar' }
  end
end
