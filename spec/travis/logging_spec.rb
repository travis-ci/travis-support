require 'spec_helper'
require 'travis/support'
require 'stringio'
require 'logger'
require 'hashr'

describe Travis::Logging do
  class Foo
    include Travis::Logging

    log_header { 'header' }

    def do_something(*args)
    end
    log :do_something
  end

  let(:io)     { StringIO.new }
  let(:log)    { io.string }
  let(:object) { Foo.new }

  before :each do
    Travis.logger = Logger.new(io)
    Travis.stubs(:config).returns(Hashr.new(log_level: :info))
  end

  describe '.log' do
    it 'logs before the method call' do
      object.do_something(:foo, :bar)
      log.should include('about to do_something')
    end

    it 'logs after the method call' do
      object.do_something(:foo, :bar)
      log.should include('done: do_something')
    end

    it 'includes the log header' do
      object.do_something(:foo, :bar)
      log.should include('header')
    end

    it 'includes the thread id' do
      object.do_something(:foo, :bar)
      expect(io.string).to match(/TID=\w+/)
    end
  end

  describe '.log_level' do
    after :each do
      Travis.send(:remove_const, :Worker) if defined?(Travis::Worker)
    end

    it 'returns Travis::Worker.config.log_level if defined' do
      Travis.const_set(:Worker, Module.new)
      Travis::Worker.stubs(:config).returns(Hashr.new(log_level: :info))
      Travis::Logging.log_level.should == :info
    end

    it 'returns Travis.config.log_level if defined' do
      Travis::Logging.log_level.should == :info
    end

    it 'returns :debug by default' do
      Travis.stubs(:respond_to?).with(:config).returns(false)
      Travis::Logging.log_level.should == :debug
    end
  end

  describe 'log_exception' do
    let(:exception) { Exception.new('kaputt!').tap { |e| e.set_backtrace(['line 1', 'line 2']) } }

    it 'logs the exception message' do
      object.log_exception(exception)
      log.should include('kaputt!')
    end

    it 'logs the backtrace' do
      object.log_exception(exception)
      log.should include("line 1")
      log.should include("line 2")
    end
  end

  describe Travis::Logging::Format do
    let(:logger) { Logger.new(io).tap { |logger| logger.formatter = Travis::Logging::Format.new } }

    before :each do
      ENV.delete('TRAVIS_PROCESS_NAME')
    end

    it 'includes the severity as a single char' do
      logger.info('message')
      log.should =~ /^I /
    end

    it 'includes the message' do
      logger.info('message')
      log.should =~ / message$/
    end

    it 'includes the timestamp if config.time_format is given' do
      logger.formatter = Travis::Logging::Format.new(time_format: '%Y-%m-%dT%H:%M:%S.%6N%:z')
      logger.info('message')
      log.should =~ /^[\d]{4}-[\d]{2}-[\d]{2}T[\d]{2}:[\d]{2}:[\d]{2}\.[\d]{6}\+[\d]{2}:[\d]{2}/
    end

    it 'does not include the timestamp if config.time_format is not given' do
      logger.info('message')
      log.should_not =~ /^[\d]{4}-[\d]{2}-[\d]{2}T[\d]{2}:[\d]{2}:[\d]{2}\.[\d]{6}\+[\d]{2}:[\d]{2}/
    end

    it 'includes the current thread id if config.thread_id is given' do
      logger.formatter = Travis::Logging::Format.new(thread_id: true)
      logger.info('message')
      log.should include(Thread.current.object_id.to_s)
    end

    it 'does not include the current thread id if config.thread_id is not given' do
      logger.info('message')
      log.should_not include(Thread.current.object_id.to_s)
    end

    it 'includes the current process id if config.process_id is given' do
      logger.formatter = Travis::Logging::Format.new(process_id: true)
      logger.info('message')
      log.should include(Process.pid.to_s)
    end

    it 'does not include the current process id if config.process_id is not given' do
      logger.info('message')
      log.should_not include(Process.pid.to_s)
    end

    it 'includes the process name if ENV["TRAVIS_PROCESS_NAME"] is present' do
      ENV['TRAVIS_PROCESS_NAME'] = 'hub.1'
      logger.info('message')
      log.should include('app[hub.1]: ')
    end

    it 'does not include the process name if ENV["TRAVIS_PROCESS_NAME"] is not present' do
      logger.info('message')
      log.should_not include('app[hub.1]: ')
    end
  end

  describe 'error' do
    context 'with exception' do
      let(:exception) { StandardError.new('kaputt!').tap { |e| e.set_backtrace(['line 1', 'line 2']) } }

      it 'logs the exception message' do
        object.error(exception)
        io.string.should include('kaputt!')
      end

      it 'logs the backtrace' do
        object.error(exception)
        io.string.should include("line 1")
        io.string.should include("line 2")
      end
    end
  end
end
