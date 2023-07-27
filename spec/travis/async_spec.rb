# frozen_string_literal: true

require 'spec_helper'
require 'core_ext/module/include'

describe Travis::Async do
  before do
    described_class.enabled = true
  end

  after do
    described_class.enabled = false
    described_class::Threaded.queues.clear
  end

  describe 'queue name' do
    let(:async_object) do
      Class.new do
        extend Travis::Async
        def self.name
          'Class'
        end

        def async_method; end
        async :async_method, use: :threaded
      end
    end

    it "uses the given object's class name as queue name" do
      async_object.new.async_method
      described_class::Threaded.queues.keys.should == ['Class']
    end
  end

  describe 'Travis::Async.enabled' do
    let(:async_object) do
      Class.new do
        extend Travis::Async
        def async_method; end
        async :async_method, use: :threaded
      end
    end

    it 'enables queueing' do
      described_class.enabled = true
      async_object.new.async_method
      described_class::Threaded.queues.should_not be_empty
    end

    it 'disables queueing' do
      described_class.enabled = false
      async_object.new.async_method
      described_class::Threaded.queues.should be_empty
    end
  end

  describe 'Travis::Async::Inline' do
    let(:target) do
      Class.new do
        def perform; end
      end
    end

    it 'is the default strategy' do
      described_class.strategy(nil) == 'Inline'
    end

    it 'calls the method inline' do
      target.expects(:perform).with(:foo)
      described_class.run(target, :perform, { use: :inline }, :foo)
    end
  end
end
