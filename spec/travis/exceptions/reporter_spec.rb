# frozen_string_literal: true

require 'spec_helper'
require 'hashr'

describe Travis::Exceptions::Reporter do
  let(:reporter) { described_class.new }
  let(:error)    { StandardError.new }

  before do
    described_class.queue = Queue.new
    Travis.stubs(:config).returns(Hashr.new(sentry: {}))
  end

  it 'setup a queue' do
    reporter.queue.should be_instance_of(Queue)
  end

  it 'loops in a separate thread' do
    reporter.expects(:error_loop)
    reporter.run
    reporter.thread.join
  end

  it 'reports an error when something is on the queue' do
    reporter.adapter.expects(:handle)
    reporter.queue.push(error)
    reporter.pop
  end

  it 'does not raise an error when pop fails' do
    reporter.queue.expects(:pop).raises(error)
    expect { reporter.pop }.not_to raise_error
  end

  it 'allows pushing an error on the queue' do
    described_class.enqueue(error)
    reporter.queue.pop.should == [error, {}]
  end

  it 'adds custom metadata to raven' do
    error.stubs(:metadata).returns('metadata' => 'metadata')
    metadata = reporter.metadata_for(error)
    reporter.adapter.expects(:handle).with(error, { extra: metadata }, {})
    reporter.handle(error)
  end

  describe 'with no sentry dsn configured' do
    it 'uses the logger adapter' do
      reporter.adapter.should be_instance_of(Travis::Exceptions::Adapter::Logger)
    end
  end

  describe 'with a sentry dsn configured' do
    let(:config) { JSON.parse({ sentry: { dsn: 'https://app.getsentry.com/1', ssl: 'ssl' } }.to_json, object_class: OpenStruct) }

    it 'uses the sentry adapter' do
      Travis.stubs(:config).returns(config)
      reporter.adapter.should be_instance_of(Travis::Exceptions::Adapter::Sentry)
    end

    it 'sets the sentry adapter up with the required arguments' do
      Travis.stubs(:config).returns(config)
      Travis::Exceptions::Adapter::Sentry.expects(:new).with(config, Travis.logger, env: Travis.env)
      reporter.adapter
    end
  end
end
