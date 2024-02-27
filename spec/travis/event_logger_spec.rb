# frozen_string_literal: true

require 'spec_helper'
require 'travis/support/event_logger'
require 'active_support'

describe Travis::EventLogger do
  let(:notifications) { [] }

  around do |example|
    callback = ->(*a) { notifications << a }
    if ActiveSupport::Notifications.respond_to? :subscribed
      ActiveSupport::Notifications.subscribed(callback, //) { example.run }
    else
      subscription = ActiveSupport::Notifications.subscribe(//, &callback)
      example.run
      ActiveSupport::Notifications.unsubscribe subscription
    end
  end

  describe '.notify' do
    def args
      Array notifications.last
    end

    def data
      args.last
    end

    def event_name
      args.first
    end

    it 'suffixes events with .travis' do
      described_class.notify 'foo'
      event_name.should be == 'foo.travis'
    end

    it 'transforms payload into a hash' do
      described_class.notify 'foo', 'bar'
      data.should be_a(Hash)
      data[:payload].should be == 'bar'
    end

    it 'does keep the payload as hash' do
      described_class.notify 'foo', foo: 'bar'
      data[:foo].should be == 'bar'
    end

    it 'allows passing in a block for instrumentation' do
      described_class.notify('foo', 'bar') {}
      args.count.should be == 5
      data[:instrumented].should == true
    end

    it 'returns the block value' do
      described_class.notify('foo', 'bar') { 42 }.should be == 42
    end
  end

  describe '.subscribe' do
    attr_reader :subscription, :name, :payload

    before do
      @subscription = described_class.subscribe 'foo' do |name, payload|
        @name = name
        @payload = payload
      end
    end

    after do
      ActiveSupport::Notifications.unsubscribe subscription
    end

    it 'sets the full name' do
      described_class.notify 'foo'
      name.should be == 'foo.travis'
    end

    it 'subscribes to child events' do
      described_class.notify 'bar.foo'
      name.should be == 'bar.foo.travis'
    end

    it 'requires a dot for nesting child events' do
      described_class.notify 'barfoo'
      name.should be_nil
    end

    it 'exposes the payload' do
      described_class.notify 'foo', bar: 42
      payload[:bar].should be == 42
    end

    it 'hands on the event for instrumentation' do
      described_class.notify('foo', 'bar') {}
      payload[:instrumented].should
      payload[:event].should respond_to(:duration)
    end
  end

  describe '.scope' do
    attr_reader :subscription, :name, :payload

    before do
      @subscription = described_class.subscribe 'foo' do |name, payload|
        @name = name
        @payload = payload
      end
    end

    after do
      ActiveSupport::Notifications.unsubscribe subscription
    end

    it 'adds values to the notification' do
      described_class.scope bar: 42 do
        described_class.notify 'foo'
      end

      payload[:bar].should be == 42
    end

    it 'works for more than one notification' do
      described_class.scope bar: 42 do
        described_class.notify 'foo'
        described_class.notify 'foo'
      end

      payload[:bar].should be == 42
    end

    it 'does not affect other notifications' do
      described_class.scope bar: 42 do
        described_class.notify 'foo'
      end

      described_class.notify 'foo'
      payload[:bar].should be_nil
    end

    it 'keeps notification payload' do
      described_class.scope bar: 42 do
        described_class.notify 'foo', baz: 1337
      end

      payload[:baz].should be == 1337
    end

    it 'prefers notification payload over scope' do
      described_class.scope bar: 42 do
        described_class.notify 'foo', bar: 1337
      end

      payload[:bar].should be == 1337
    end

    it 'allows nesting' do
      described_class.scope a: :a do
        described_class.scope b: :b do
          described_class.notify 'foo', c: :c
        end
      end

      payload.should be == { a: :a, b: :b, c: :c }
    end

    it 'prefers inner scope over outer scope' do
      described_class.scope a: :a do
        described_class.scope a: :b do
          described_class.notify 'foo'
        end
      end

      payload[:a].should be == :b
    end
  end
end
