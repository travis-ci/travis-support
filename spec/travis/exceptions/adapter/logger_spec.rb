require 'spec_helper'

describe Travis::Exceptions::Adapter::Logger do
  let(:adapter)   { Travis::Exceptions::Adapter::Logger.new }
  let(:logger)    { stub(error: nil) }
  let(:error)     { StandardError.new('message') }

  before :each do
    Travis.stubs(:logger).returns(logger)
  end

  it 'logs the message' do
    logger.expects(:error).with('message')
    adapter.handle(error)
  end

  it 'logs the backtrace' do
    backtrace = ['backtrace']
    error.stubs(:backtrace).returns(backtrace)
    logger.expects(:error).with(backtrace)
    adapter.handle(error)
  end

  it 'logs the message' do
    logger.expects(:error).with(['foo: foo'])
    adapter.handle(error, extra: { foo: 'foo' })
  end
end
