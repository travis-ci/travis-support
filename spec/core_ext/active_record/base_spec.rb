require 'core_ext/active_record/base'

describe ActiveRecord::Base, 'extensions' do
  describe 'floor' do
    subject { ActiveRecord::Base }

    def using(adapter)
      subject.stubs(:configurations).returns('test' => { 'adapter' => adapter})
    end

    it 'returns an sql snippet for postgres' do
      using 'postgresql'
      expect(subject.floor(:number)).to eq('floor(number::float)')
    end

    it 'returns an sql snippet for mysql' do
      using 'mysql'
      expect(subject.floor(:number)).to eq('floor(number)')
    end

    it 'returns an sql snippet for sqlite3' do
      using 'sqlite3'
      expect(subject.floor(:number)).to eq('round(number - 0.5)')
    end
  end
end
