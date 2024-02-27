# frozen_string_literal: true

require 'spec_helper'
require 'active_support/core_ext/hash/except'
require 'metriks'

describe Travis::Instrumentation do
  let(:klass) do
    Class.new do
      extend Travis::Instrumentation

      def self.name
        'Travis::Foo::Bar'
      end

      def tracked(*_args)
        inner
      end
      instrument :tracked, scope: :scope, track: true

      def inner
        'result'
      end

      def scope
        'baz'
      end
    end
  end

  let(:object) { klass.new }
  let(:timer)  { stub('timer', update: true) }
  let(:events) { [] }

  before do
    @subscriber = ActiveSupport::Notifications.subscribe(/travis\./) do |key, args|
      events << [key, args]
    end
  end

  after do
    klass.instrumentation_key = nil
    ActiveSupport::Notifications.unsubscribe(@subscriber)
  end

  describe 'instruments the method' do
    it 'sends received events' do
      object.tracked('foo')
      key, args = events.first
      key.should
      args.except(:started_at, :level).should
      args[:started_at].should be_a(Float)
    end

    it 'sends completed events' do
      object.tracked('foo')
      key, args = events.last
      key.should
      args.except(:started_at, :finished_at,
                  :level).should
      args[:started_at].should be_a(Float)
      args[:finished_at].should be_a(Float)
    end

    it 'sends all completed events' do
      object.stubs(:inner).raises(StandardError, 'I FAIL!')
      begin
        object.tracked('foo')
      rescue StandardError
        nil
      end
      key, args = events.last
      key.should
      args[:target].should
      object
      args[:args].should
      args[:exception].should == ['StandardError', 'I FAIL!']
    end

    it 'sends out just two notifications' do
      object.tracked('foo')
      events.size.should == 2
    end
  end

  describe 'inheriting classes' do
    let(:child) do
      Class.new(klass) do
        def self.name
          'Travis::Something'
        end
      end
    end
    let(:object) { child.new }

    it 'use the child class name as the instrumentation key by default' do
      object.tracked('foo')
      key, = events.first
      key.should == 'travis.something.baz.tracked:received'
    end

    it 'can overwrite the instrumentation key' do
      child.instrumentation_key = 'travis.something.else'
      object.tracked('foo')
      key, = events.first
      key.should == 'travis.something.else.baz.tracked:received'
    end
  end

  describe 'instrumentation_key' do
    it 'holds separate values on different classes' do
      one = Class.new(klass) do
        def self.name
          'Travis::One'
        end
      end
      two = Class.new(klass) do
        def self.name
          'Travis::Two'
        end
      end
      one.instrumentation_key = 'travis.one.foo'
      two.instrumentation_key = 'travis.two.bar'
      one.instrumentation_key.should
      two.instrumentation_key.should == 'travis.two.bar'
    end
  end

  describe 'calling the method' do
    it 'meters execution of the method' do
      described_class.expects(:meter).with('travis.foo.bar.baz.tracked:completed', anything)
      object.tracked
    end

    it 'still returns the return value of the instrumented method' do
      object.tracked.should == 'result'
    end

    it 'reraises the exception from the failed method call' do
      object.stubs(:inner).raises(StandardError)
      -> { object.tracked }.should raise_error(StandardError)
    end
  end

  describe 'meters events' do
    let(:meter) { stub('meter', mark: true) }
    let(:timer) { stub('timer', update: true) }

    before do
      Metriks.stubs(:meter).returns(meter)
      Metriks.stubs(:timer).returns(timer)
    end

    it 'meters that the method call is completed' do
      described_class.expects(:meter).with('travis.foo.bar.baz.tracked:completed', anything)
      object.tracked
    end

    it 'meters that the method call has failed' do
      object.stubs(:inner).raises(StandardError)
      described_class.expects(:meter).with('travis.foo.bar.baz.tracked:failed', anything)
      begin
        object.tracked
      rescue StandardError
        nil
      end
    end
  end

  describe 'levels' do
    let(:event) { events.last }
    let(:args) { event.last }
    let(:level) { args[:level] }

    it 'defaults the level to :info' do
      object.tracked('foo')
      level.should == :info
    end

    it 'may be set as option' do
      klass.send(:define_method, :other) {}
      klass.instrument :other, level: :error, scope: :scope, track: true

      object.other
      level.should == :error
    end

    it 'does not record metrics for debug level' do
      Metriks.expects(:meter).never
      Metriks.expects(:timer).never

      klass.send(:define_method, :other) {}
      klass.instrument :other, level: :debug, scope: :scope, track: true
      object.other
    end
  end
end
