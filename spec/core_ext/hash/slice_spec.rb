require 'core_ext/hash/slice'

describe 'Hash#slice' do
  it 'returns a new hash containing the given keys' do
    hash = { :foo => 'foo', :bar => 'bar', :baz => 'baz' }
    expect(hash.slice(:foo, :bar)).to eq({ :foo => 'foo', :bar => 'bar' })
  end
end
