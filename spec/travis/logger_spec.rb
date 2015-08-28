require 'stringio'
require 'hashr'

describe Travis::Logger do
  let(:io)     { StringIO.new }
  let(:log)    { io.string }
  let(:logger) { Travis::Logger.new(io) }

  before :each do
    Travis.stubs(:config).returns(Hashr.new(log_level: :info))
  end

  describe '.log_level' do
    after :each do
      Travis.send(:remove_const, :Worker) if defined?(Travis::Worker)
    end

    it 'returns Travis::Worker.config.log_level if defined' do
      Travis.const_set(:Worker, Module.new)
      Travis::Worker.stubs(:config).returns(Hashr.new(log_level: :info))
      expect(Travis::Logger.log_level).to eq(:info)
    end

    it 'returns Travis.config.log_level if defined' do
      expect(Travis::Logger.log_level).to eq(:info)
    end

    it 'returns :debug by default' do
      Travis.stubs(:respond_to?).with(:config).returns(false)
      expect(Travis::Logger.log_level).to eq(:debug)
    end
  end

  describe 'error' do
    context 'with exception' do
      let(:exception) { StandardError.new('kaputt!').tap { |e| e.set_backtrace(['line 1', 'line 2']) } }

      it 'logs the exception message' do
        logger.error(exception)
        expect(io.string).to include('kaputt!')
      end

      it 'logs the backtrace' do
        logger.error(exception)
        expect(io.string).to include("line 1")
        expect(io.string).to include("line 2")
      end
    end
  end
end
