require 'core_ext/array/flatten_once'

describe Array, 'extensions' do
  describe 'flatten_once' do
    let(:array) { ['foo', ['bar'], [['baz']]] }

    it 'flattens an array at the first level but does not flatten child arrays' do
      expect(array.flatten_once).to eq(['foo', 'bar', ['baz']])
    end
  end
end
