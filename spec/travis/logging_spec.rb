require 'spec_helper'
require 'travis/support'
require 'stringio'
require 'logger'

describe Travis::Logging do
  class Foo
    include Travis::Logging

    log_header { 'header' }

    def do_something(*args)
    end
    log :do_something
  end

  let(:io)     { StringIO.new }
  let(:object) { Foo.new }

  before :each do
    Travis.logger = Logger.new(io)
  end

  describe '.log' do
    it 'logs before the method call' do
      object.do_something(:foo, :bar)
      io.string.should include('about to do_something')
    end

    it 'logs after the method call' do
      object.do_something(:foo, :bar)
      io.string.should include('done: do_something')
    end

    it 'includes the log header' do
      object.do_something(:foo, :bar)
      io.string.should include('header')
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
      Travis::Worker.stubs(:config).returns(stub(:log_level => :info))
      Travis::Logging.log_level.should == :info
    end

    it 'returns Travis.config.log_level if defined' do
      Travis.stubs(:config).returns(stub(:log_level => :info))
      Travis::Logging.log_level.should == :info
    end

    it 'returns :debug by default' do
      Travis::Logging.log_level.should == :debug
    end
  end

  describe 'log_exception' do
    let(:exception) { Exception.new('kaputt!').tap { |e| e.set_backtrace(['line 1', 'line 2']) } }

    it 'logs the exception message' do
      object.log_exception(exception)
      io.string.should include('kaputt!')
    end

    it 'logs the backtrace' do
      object.log_exception(exception)
      io.string.should include("line 1")
      io.string.should include("line 2")
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
