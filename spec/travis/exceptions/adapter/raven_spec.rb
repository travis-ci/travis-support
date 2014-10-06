require 'spec_helper'
require 'hashr'

describe Travis::Exceptions::Adapter::Raven do
  let(:adapter) { Travis::Exceptions::Adapter::Raven.new(config, logger, env: 'test') }
  let(:config)  { Hashr.new(sentry: { dsn: 'https://app.getsentry.com/1', ssl: 'ssl' }) }
  let(:logger)  { stub(error: nil, info: nil, debug: nil, level: Logger::INFO) }
  let(:error)   { StandardError.new('message') }

  before :each do
    Raven.stubs(:capture_exception)
  end

  it 'captures the error on raven' do
    Raven.expects(:capture_exception).with(error, {})
    adapter.handle(error)
  end

  it 'captures the metadata on raven' do
    Raven.expects(:capture_exception).with(error, foo: 'foo')
    adapter.handle(error, foo: 'foo')
  end

  it 'logs the error' do
    logger.expects(:error).with('Error: message')
    adapter.handle(error)
  end

  it 'logs the backtrace if log level is set to debug' do
    logger.stubs(:level).returns(Logger::DEBUG)
    error.stubs(:backtrace).returns(['backtrace'])
    logger.expects(:error).with("Error: message\nbacktrace")
    adapter.handle(error)
  end
end

