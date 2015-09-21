require 'spec_helper'
require 'travis/support'
require 'stringio'

describe Travis::Logger::Format do
  let(:io) { StringIO.new }
  let(:log) { io.string }
  let(:formatter) { Travis::Logger::Format.new }
  let(:logger) { Travis::Logger.new(io).tap { |logger| logger.formatter = formatter } }

  context 'when using traditional format' do
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
      logger.formatter = Travis::Logger::Format.new(time_format: '%Y-%m-%dT%H:%M:%S.%6N%:z')
      logger.info('message')
      log.should =~ /^[\d]{4}-[\d]{2}-[\d]{2}T[\d]{2}:[\d]{2}:[\d]{2}\.[\d]{6}[\-\+][\d]{2}:[\d]{2}/
    end

    it 'does not include the timestamp if config.time_format is not given' do
      logger.info('message')
      log.should_not =~ /^[\d]{4}-[\d]{2}-[\d]{2}T[\d]{2}:[\d]{2}:[\d]{2}\.[\d]{6}[\-\+][\d]{2}:[\d]{2}/
    end

    it 'includes the current thread id if config.thread_id is given' do
      logger.formatter = Travis::Logger::Format.new(thread_id: true)
      logger.info('message')
      log.should include(Thread.current.object_id.to_s)
    end

    it 'does not include the current thread id if config.thread_id is not given' do
      logger.info('message')
      log.should_not include(Thread.current.object_id.to_s)
    end

    it 'includes the current process id if config.process_id is given' do
      logger.formatter = Travis::Logger::Format.new(process_id: true)
      logger.info('message')
      log.should include(Process.pid.to_s)
    end

    it 'does not include the current process id if config.process_id is not given' do
      logger.info('message')
      log.should_not include(Process.pid.to_s)
    end

    it 'includes the current thread id if config.thread_id is given' do
      logger.formatter = Travis::Logger::Format.new(thread_id: true)
      logger.info('message')
      log.should include(Thread.current.object_id.to_s)
    end

    it 'does not include the current thread id if config.thread_id is not given' do
      logger.info('message')
      log.should_not include(Thread.current.object_id.to_s)
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

  context 'when using l2met format' do
    let(:formatter) { Travis::Logger::Format.new(format_type: 'l2met') }

    before :each do
      ENV.delete('TRAVIS_PROCESS_NAME')
    end

    it 'includes the severity' do
      logger.info('message')
      expect(log).to include('level=info')
    end

    it 'includes the quoted message' do
      logger.info('message with spaces')
      expect(log).to include('msg="message with spaces"')
    end

    it 'includes the message' do
      logger.info('message')
      expect(log).to include('msg=message')
    end

    it 'includes the timestamp if config.time_format is given' do
      logger.formatter = Travis::Logger::Format.new(format_type: 'l2met', time_format: '%Y-%m-%dT%H:%M:%S.%6N%:z')
      logger.info('message')
      expect(log).to match(/time=[\d]{4}-[\d]{2}-[\d]{2}T[\d]{2}:[\d]{2}:[\d]{2}\.[\d]{6}[\-\+][\d]{2}:[\d]{2}/)
    end

    it 'includes the timestamp as iso8601 if config.time_format is not given' do
      logger.info('message')
      expect(log).to match(/time=[\d]{4}-[\d]{2}-[\d]{2}T[\d]{2}:[\d]{2}:[\d]{2}[\-\+][\d]{2}:[\d]{2}/)
    end

    it 'includes the current thread id if config.thread_id is given' do
      logger.formatter = Travis::Logger::Format.new(format_type: 'l2met', thread_id: true)
      logger.info('message')
      expect(log).to include("tid=#{Thread.current.object_id}")
    end

    it 'does not include the current thread id if config.thread_id is not given' do
      logger.info('message')
      expect(log).to_not include("tid=#{Thread.current.object_id}")
    end

    it 'includes the current process id if config.process_id is given' do
      logger.formatter = Travis::Logger::Format.new(format_type: 'l2met', process_id: true)
      logger.info('message')
      expect(log).to include("pid=#{Process.pid}")
    end

    it 'does not include the current process id if config.process_id is not given' do
      logger.info('message')
      expect(log).to_not include("pid=#{Process.pid}")
    end

    it 'includes the current thread id if config.thread_id is given' do
      logger.formatter = Travis::Logger::Format.new(format_type: 'l2met', thread_id: true)
      logger.info('message')
      expect(log).to include("tid=#{Thread.current.object_id}")
    end

    it 'does not include the current thread id if config.thread_id is not given' do
      logger.info('message')
      expect(log).to_not include("tid=#{Thread.current.object_id}")
    end

    it 'includes the process name if ENV["TRAVIS_PROCESS_NAME"] is present' do
      ENV['TRAVIS_PROCESS_NAME'] = 'hub.1'
      logger.info('message')
      expect(log).to include('app=hub.1')
    end

    it 'includes arbitrary key=value pairs' do
      logger.info('message', foo: 'bar', energy: 9001)
      expect(log).to include('foo=bar')
      expect(log).to include('energy=9001')
    end

    it 'does not include the process name if ENV["TRAVIS_PROCESS_NAME"] is not present' do
      logger.info('message')
      expect(log).to_not include('app=hub.1')
    end
  end
end
