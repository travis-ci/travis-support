require 'core_ext/hash/deep_symbolize_keys'

describe 'Hash#deep_symbolize_keys' do
  it 'symbolizes keys for nested hashes' do
    hash = { 'foo' => { 'bar' => 'baz' } }
    expect(hash.deep_symbolize_keys).to eq({ :foo => { :bar => 'baz' } })
  end

  it 'symbolizes keys for hashes within nested arrays' do
    hash = { 'foo' => [{ 'bar' => 'baz' }] }
    expect(hash.deep_symbolize_keys).to eq({ :foo => [{ :bar => 'baz' }] })
  end
end

describe 'Hash#deep_symbolize_keys!' do
  it 'replaces with deep_symbolized self' do
    hash = { 'foo' => { 'bar' => 'baz' } }
    hash.deep_symbolize_keys!
    expect(hash).to eq({ :foo => { :bar => 'baz' } })
  end
end
