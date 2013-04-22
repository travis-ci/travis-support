require 'spec_helper'
require 'raven'

describe Travis::Exceptions::Reporter do
  let(:reporter) { Travis::Exceptions::Reporter.new }

  before :each do
    Travis::Exceptions::Reporter.queue = Queue.new
    Travis.stubs(:config).returns(stub(:sentry => stub(:dsn => '')))
    reporter.stubs(:enabled?).returns(true)
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
    Raven.expects(:capture_exception)
    reporter.queue.push(StandardError.new)
    reporter.pop
  end

  it "should not raise an error when pop fails" do
    reporter.queue.expects(:pop).raises(StandardError.new)
    expect { reporter.pop }.to_not raise_error
  end

  it "should allow pushing an error on the queue" do
    error = StandardError.new
    Travis::Exceptions::Reporter.enqueue(error)
    reporter.queue.pop.should == error
  end

  it "should add custom metadata to hubble" do
    exception = Class.new(StandardError) do
      def metadata
        { 'metadata' => 'metadata' }
      end
    end.new

    metadata = reporter.metadata_for(exception)

    Raven.expects(:capture_exception).with(exception, extra: metadata)
    reporter.handle(exception)
  end

  it "should add the travis environment to hubble" do
    exception = StandardError.new

    metadata = reporter.metadata_for(exception)
    Raven.expects(:capture_exception).with(exception, extra: metadata)

    reporter.handle(exception)

    metadata['env'].should == 'development'
  end
end

