require 'core_ext/module/include'
require 'travis/support/async'

describe Travis::Async do
  before :each do
    Travis::Async.enabled = true
  end

  after :each do
    Travis::Async.enabled = false
    Travis::Async::Threaded.queues.clear
  end

  describe 'declaring a method as async' do
    let(:async_sleep) do
      Class.new do
        extend Travis::Async

        attr_accessor :done

        def initialize
          @done = Hash[*(1..5).map { |queue| [queue, 0] }.flatten]
        end

        def total_done
          done.values.inject(&:+)
        end

        1.upto(5) do |queue|
          define_method(:"sleep_in_queue_#{queue}") do |seconds|
            sleep(seconds)
            done[queue] ||= 0
            done[queue] += 1
          end
          async :"sleep_in_queue_#{queue}", :queue => queue
        end
      end
    end
  end

  describe 'queue name' do
    let(:async_object) do
      Class.new do
        extend Travis::Async
        def self.name; 'Class' end
        def async_method; end
        async :async_method, use: :threaded
      end
    end

    it "uses the given object's class name as queue name" do
      async_object.new.async_method
      expect(Travis::Async::Threaded.queues.keys).to eq(['Class'])
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
      Travis::Async.enabled = true
      async_object.new.async_method
      expect(Travis::Async::Threaded.queues).to_not be_empty
    end

    it 'disables queueing' do
      Travis::Async.enabled = false
      async_object.new.async_method
      expect(Travis::Async::Threaded.queues).to be_empty
    end
  end

  describe 'Travis::Async::Inline' do
    let(:target) do
      Class.new do
        def perform; end
      end
    end

    it 'is the default strategy' do
      Travis::Async.strategy(nil) == 'Inline'
    end

    it 'calls the method inline' do
      target.expects(:perform).with(:foo)
      Travis::Async.run(target, :perform, { use: :inline }, :foo)
    end
  end
end



