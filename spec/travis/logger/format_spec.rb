require 'stringio'

describe Travis::Logger::Format do
  let(:io)     { StringIO.new }
  let(:log)    { io.string }
  let(:logger) { Logger.new(io).tap { |logger| logger.formatter = Travis::Logger::Format.new } }

  # before :each do
  #   Travis.logger = Logger.new(io)
  #   Travis.stubs(:config).returns(Hashr.new(log_level: :info))
  # end

  before :each do
    ENV.delete('TRAVIS_PROCESS_NAME')
  end

  it 'includes the severity as a single char' do
    logger.info('message')
    expect(log).to match(/^I /)
  end

  it 'includes the message' do
    logger.info('message')
    expect(log).to match(/ message$/)
  end

  it 'includes the timestamp if config.time_format is given' do
    logger.formatter = Travis::Logger::Format.new(time_format: '%Y-%m-%dT%H:%M:%S.%6N%:z')
    logger.info('message')
    expect(log).to match(/^[\d]{4}-[\d]{2}-[\d]{2}T[\d]{2}:[\d]{2}:[\d]{2}\.[\d]{6}\+[\d]{2}:[\d]{2}/)
  end

  it 'does not include the timestamp if config.time_format is not given' do
    logger.info('message')
    expect(log).to_not match(/^[\d]{4}-[\d]{2}-[\d]{2}T[\d]{2}:[\d]{2}:[\d]{2}\.[\d]{6}\+[\d]{2}:[\d]{2}/)
  end

  it 'includes the current thread id if config.thread_id is given' do
    logger.formatter = Travis::Logger::Format.new(thread_id: true)
    logger.info('message')
    expect(log).to include(Thread.current.object_id.to_s[-4, 4])
  end

  it 'does not include the current thread id if config.thread_id is not given' do
    logger.info('message')
    expect(log).to_not include(Thread.current.object_id.to_s[-4, 4])
  end

  it 'includes the current process id if config.process_id is given' do
    logger.formatter = Travis::Logger::Format.new(process_id: true)
    logger.info('message')
    expect(log).to include(Process.pid.to_s)
  end

  it 'does not include the current process id if config.process_id is not given' do
    logger.info('message')
    expect(log).to_not include(Process.pid.to_s)
  end

  it 'includes the process name if ENV["TRAVIS_PROCESS_NAME"] is present' do
    ENV['TRAVIS_PROCESS_NAME'] = 'hub.1'
    logger.info('message')
    expect(log).to include('app[hub.1]: ')
  end

  it 'does not include the process name if ENV["TRAVIS_PROCESS_NAME"] is not present' do
    logger.info('message')
    expect(log).to_not include('app[hub.1]: ')
  end
end
