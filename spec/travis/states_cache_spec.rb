require 'spec_helper'
require 'travis/support/states_cache'

module Travis
  describe StatesCache do
    let(:adapter) { StatesCache::Test.new }
    subject { StatesCache.new(adapter: adapter) }

    it 'allows to fetch state' do
      adapter.expects(:fetch).with(1, 'master').returns({'state' => 'passed'})
      expect(subject.fetch_state(1, 'master')).to eq(:passed)
    end

    # it 'gets data from build if it\'s given instead of raw data' do
    #   build = Factory(:build, state: :passed)
    #   data = { id: build.id, state: 'passed' }.stringify_keys

    #   adapter.expects(:write).with(1, 'master', data)
    #   subject.write(1, 'master', build)
    # end

    it 'delegates #write to adapter' do
      data = { id: 10, state: 'passed' }.stringify_keys
      adapter.expects(:write).with(1, 'master', data)
      subject.write(1, 'master', data)
    end

    it 'delegates #fetch to adapter' do
      adapter.expects(:fetch).with(1, 'master').returns({ foo: 'bar' })
      expect(subject.fetch(1, 'master')).to eq({ foo: 'bar' })
    end

    describe 'integration' do
      let(:client) { Dalli::Client.new('localhost:11211') }
      let(:adapter) { StatesCache::Memcached.new(client: client) }

      before do
        begin
          client.flush
        rescue Dalli::DalliError => e
          pending "Dalli can't run properly, skipping. Cause: #{e.message}"
          fail
        end
      end

      it 'saves the state for given branch and globally' do
        data = { id: 10, state: 'passed' }.stringify_keys
        subject.write(1, 'master', data)
        expect(subject.fetch(1)['state']).to eq('passed')
        subject.fetch(1, expect('master')['state']).to eq('passed')

        expect(subject.fetch(2)).to be_nil
        expect(subject.fetch(2, 'master')).to be_nil
      end

      it 'updates the state only if the info is newer' do
        data = { id: 10, state: 'passed' }.stringify_keys
        subject.write(1, 'master', data)

        subject.fetch(1, expect('master')['state']).to eq('passed')

        data = { id: 12, state: 'failed' }.stringify_keys
        subject.write(1, 'development', data)

        subject.fetch(1, expect('master')['state']).to eq('passed')
        subject.fetch(1, expect('development')['state']).to eq('failed')
        expect(subject.fetch(1)['state']).to eq('failed')

        data = { id: 11, state: 'errored' }.stringify_keys
        subject.write(1, 'master', data)

        subject.fetch(1, expect('master')['state']).to eq('errored')
        subject.fetch(1, expect('development')['state']).to eq('failed')
        expect(subject.fetch(1)['state']).to eq('failed')
      end

      it 'updates the state if the id of the build is the same' do
        data = { id: 10, state: 'failed' }.stringify_keys
        subject.write(1, 'master', data)

        subject.fetch(1, expect('master')['state']).to eq('passed')

        data = { id: 10, state: 'passed' }.stringify_keys
        subject.write(1, 'master', data)

        subject.fetch(1, expect('master')['state']).to eq('passed')
      end

      it 'handles connection errors gracefully' do
        data = { id: 10, state: 'passed' }.stringify_keys
        client = Dalli::Client.new('illegalserver:11211')
        adapter = StatesCache::Memcached.new(client: client)
        adapter.jitter = 0.005
        subject = StatesCache.new(adapter: adapter)
        expect {
          subject.write(1, 'master', data)
        }.to raise_error(Travis::StatesCache::CacheError)

        expect {
          subject.fetch(1)
        }.to raise_error(Travis::StatesCache::CacheError)
      end
    end

    describe StatesCache::Memcached do
      let(:client) { stub('client') }
      subject { StatesCache::Memcached.new(client: client) }

      it 'fetches the data for given id as JSON' do
        json = '{ "state": "passed", "id": 10 }'
        client.expects(:get).with('state:1').returns(json)

        expect(subject.fetch(1)).to eq({ 'state' => 'passed', 'id' => 10 })
      end

      it 'writes for both a branch and default state' do
        data = { 'id' => 10 }

        subject.expects(:update?).with(1, nil, 10).returns(true)
        subject.expects(:update?).with(1, 'master', 10).returns(true)

        client.expects(:set).with('state:1', data.to_json)
        client.expects(:set).with('state:1-master', data.to_json)

        subject.write(1, 'master', data)
      end

      context '#update?' do
        it 'returns true if persisted data is older than data passed as an argument' do
          subject.expects(:fetch).with(1, nil).returns({ 'id' => 10 })
          expect(subject.update?(1, nil, 11)).to eq(true)

          subject.expects(:fetch).with(1, 'master').returns({ 'id' => 10 })
          expect(subject.update?(1, 'master', 11)).to eq(true)
        end

        it 'returns false if persisted data is younger than data passed as an argument' do
          subject.expects(:fetch).with(1, nil).returns({ 'id' => 10 })
          expect(subject.update?(1, nil, 9)).to eq(false)

          subject.expects(:fetch).with(1, 'master').returns({ 'id' => 10})
          expect(subject.update?(1, 'master', 9)).to eq(false)
        end

        it 'returns true if persisted data is the same age' do
          subject.expects(:fetch).with(1, nil).returns({ 'id' => 10 })
          expect(subject.update?(1, nil, 10)).to eq(true)

          subject.expects(:fetch).with(1, 'master').returns({ 'id' => 10 })
          expect(subject.update?(1, 'master', 10)).to eq(true)
        end
      end
    end
  end
end
