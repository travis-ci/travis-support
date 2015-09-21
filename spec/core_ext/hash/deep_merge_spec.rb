require 'core_ext/hash/deep_merge'

describe 'Hash#deep_merge' do
  it 'deep merges a hash into a new one' do
    lft = { :foo => { :bar => 'bar' } }
    rgt = { :foo => { :baz => 'baz' } }
    expect(lft.deep_merge(rgt)).to eq({ :foo => { :bar => 'bar', :baz => 'baz' } })
  end

  it 'does not change self' do
    lft = { :foo => { :bar => 'bar' } }
    rgt = { :foo => { :baz => 'baz' } }
    lft.deep_merge(rgt)
    expect(lft.key?(:baz)).to eq(false)
  end
end

describe 'Hash#deep_merge!' do
  it 'deep merges a hash into self' do
    lft = { :foo => { :bar => 'bar' } }
    rgt = { :foo => { :baz => 'baz' } }
    lft.deep_merge!(rgt)
    expect(lft).to eq({ :foo => { :bar => 'bar', :baz => 'baz' } })
  end
end
