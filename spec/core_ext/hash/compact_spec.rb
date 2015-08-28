require 'core_ext/hash/compact'

describe Hash, 'extensions' do
  it 'compact' do
    hash     = { :a => :b, :c => nil }
    expected = { :a => :b }

    expect(hash.compact).to eq(expected)
  end

  it 'compact!' do
    hash     = { :a => :b, :c => nil }
    expected = { :a => :b }

    hash.compact!
    expect(hash).to eq(expected)
  end
end
