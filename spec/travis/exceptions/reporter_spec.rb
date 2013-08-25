require 'spec_helper'
require 'hashr'

describe Travis::Exceptions::Reporter do
  let(:reporter) { Travis::Exceptions::Reporter.new }
  let(:error)    { StandardError.new }

  before :each do
    Travis::Exceptions::Reporter.queue = Queue.new
    Travis.stubs(:config).returns(Hashr.new(sentry: {}))
  end

  it "setup a queue" do
    reporter.queue.should be_instance_of(Queue)
  end

  it "should loop in a separate thread" do
    reporter.expects(:error_loop)
    reporter.run
    reporter.thread.join
  end

  it "should report an error when something is on the queue" do
    reporter.adapter.expects(:handle)
    reporter.queue.push(error)
    reporter.pop
  end

  it "should not raise an error when pop fails" do
    reporter.queue.expects(:pop).raises(error)
    expect { reporter.pop }.to_not raise_error
  end

  it "should allow pushing an error on the queue" do
    Travis::Exceptions::Reporter.enqueue(error)
    reporter.queue.pop.should == error
  end

  it "should add custom metadata to raven" do
    error.stubs(:metadata).returns('metadata' => 'metadata')
    metadata = reporter.metadata_for(error)
    reporter.adapter.expects(:handle).with(error, extra: metadata)
    reporter.handle(error)
  end

  describe 'with no sentry dsn configured' do
    it 'uses the logger adapter' do
      reporter.adapter.should be_instance_of(Travis::Exceptions::Adapter::Logger)
    end
  end

  describe 'with a sentry dsn configured' do
    let(:config) { Hashr.new(sentry: { dsn: 'https://app.getsentry.com/1', ssl: 'ssl' }) }

    it 'uses the raven adapter' do
      Travis.stubs(:config).returns(config)
      reporter.adapter.should be_instance_of(Travis::Exceptions::Adapter::Raven)
    end

    it 'sets the raven adapter up with the required arguments' do
      Travis.stubs(:config).returns(config)
      Travis::Exceptions::Adapter::Raven.expects(:new).with(config, Travis.logger, env: Travis.env)
      reporter.adapter
    end
  end
end

