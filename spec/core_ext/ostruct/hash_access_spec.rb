require 'core_ext/ostruct/hash_access'

describe 'ostruct hash access' do
  let(:struct) { OpenStruct.new(:foo => 'foo') }

  it 'allows to read ostruct members using hash access []' do
    expect(struct[:foo]).to eq('foo')
  end

  it 'allows to write ostruct members using hash access []=' do
    struct.bar = 'bar'
    expect(struct[:bar]).to eq('bar')
  end
end
