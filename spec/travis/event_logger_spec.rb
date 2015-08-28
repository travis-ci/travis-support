require 'travis/support/event_logger'

describe Travis::EventLogger do
  let(:notifications) { [] }

  around :each do |example|
    callback = lambda { |*a| notifications << a }
    if ActiveSupport::Notifications.respond_to? :subscribed
      ActiveSupport::Notifications.subscribed(callback, //) { example.run }
    else
      subscription = ActiveSupport::Notifications.subscribe(//, &callback)
      example.run
      ActiveSupport::Notifications.unsubscribe subscription
    end
  end

  describe ".notify" do
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
      Travis::EventLogger.notify 'foo'
      expect(event_name).to eq('foo.travis')
    end

    it 'transforms payload into a hash' do
      Travis::EventLogger.notify 'foo', 'bar'
      expect(data).to be_a(Hash)
      expect(data[:payload]).to eq('bar')
    end

    it 'does keep the payload as hash' do
      Travis::EventLogger.notify 'foo', :foo => 'bar'
      expect(data[:foo]).to eq('bar')
    end

    it 'allows passing in a block for instrumentation' do
      Travis::EventLogger.notify('foo', 'bar') { }
      expect(args.count).to eq(5)
      expect(data[:instrumented]).to eq(true)
    end

    it 'returns the block value' do
      expect(Travis::EventLogger.notify('foo', 'bar') { 42 }).to eq(42)
    end
  end

  describe ".subscribe" do
    attr_reader :subscription, :name, :payload

    before do
      @subscription = Travis::EventLogger.subscribe 'foo' do |name, payload|
        @name, @payload = name, payload
      end
    end

    after do
      ActiveSupport::Notifications.unsubscribe subscription
    end

    it 'sets the full name' do
      Travis::EventLogger.notify 'foo'
      expect(name).to eq('foo.travis')
    end

    it 'subscribes to child events' do
      Travis::EventLogger.notify 'bar.foo'
      expect(name).to eq('bar.foo.travis')
    end

    it 'requires a dot for nesting child events' do
      Travis::EventLogger.notify 'barfoo'
      expect(name).to be_nil
    end

    it 'exposes the payload' do
      Travis::EventLogger.notify 'foo', :bar => 42
      expect(payload[:bar]).to eq(42)
    end

    it 'hands on the event for instrumentation' do
      Travis::EventLogger.notify('foo', 'bar') { }
      expect(payload[:instrumented]).to eq(true)
      expect(payload[:event]).to respond_to(:duration)
    end
  end

  describe ".scope" do
    attr_reader :subscription, :name, :payload

    before do
      @subscription = Travis::EventLogger.subscribe 'foo' do |name, payload|
        @name, @payload = name, payload
      end
    end

    after do
      ActiveSupport::Notifications.unsubscribe subscription
    end

    it 'adds values to the notification' do
      Travis::EventLogger.scope :bar => 42 do
        Travis::EventLogger.notify 'foo'
      end

      expect(payload[:bar]).to eq(42)
    end

    it 'works for more than one notification' do
      Travis::EventLogger.scope :bar => 42 do
        Travis::EventLogger.notify 'foo'
        Travis::EventLogger.notify 'foo'
      end

      expect(payload[:bar]).to eq(42)
    end

    it 'does not affect other notifications' do
      Travis::EventLogger.scope :bar => 42 do
        Travis::EventLogger.notify 'foo'
      end

      Travis::EventLogger.notify 'foo'
      expect(payload[:bar]).to be_nil
    end

    it 'keeps notification payload' do
      Travis::EventLogger.scope :bar => 42 do
        Travis::EventLogger.notify 'foo', :baz => 1337
      end

      expect(payload[:baz]).to eq(1337)
    end

    it 'prefers notification payload over scope' do
      Travis::EventLogger.scope :bar => 42 do
        Travis::EventLogger.notify 'foo', :bar => 1337
      end

      expect(payload[:bar]).to eq(1337)
    end

    it 'allows nesting' do
      Travis::EventLogger.scope :a => :a do
        Travis::EventLogger.scope :b => :b do
          Travis::EventLogger.notify 'foo', :c => :c
        end
      end

      expect(payload).to eq({:a => :a, :b => :b, :c => :c})
    end

    it 'prefers inner scope over outer scope' do
      Travis::EventLogger.scope :a => :a do
        Travis::EventLogger.scope :a => :b do
          Travis::EventLogger.notify 'foo'
        end
      end

      expect(payload[:a]).to eq(:b)
    end
  end
end

