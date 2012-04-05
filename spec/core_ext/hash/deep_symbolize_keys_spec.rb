require 'spec_helper'
require 'core_ext/hash/deep_symbolize_keys'

describe 'Hash#deep_symbolize_keys' do
  it 'symbolizes keys for nested hashes' do
    hash = { 'foo' => { 'bar' => 'baz' } }
    hash.deep_symbolize_keys.should == { :foo => { :bar => 'baz' } }
  end

  it 'symbolizes keys for hashes within nested arrays' do
    hash = { 'foo' => [{ 'bar' => 'baz' }] }
    hash.deep_symbolize_keys.should == { :foo => [{ :bar => 'baz' }] }
  end
end

describe 'Hash#deep_symbolize_keys!' do
  it 'replaces with deep_symbolized self' do
    hash = { 'foo' => { 'bar' => 'baz' } }
    hash.deep_symbolize_keys!
    hash.should == { :foo => { :bar => 'baz' } }
  end
end
