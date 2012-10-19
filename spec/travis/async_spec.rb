require 'spec_helper'
require 'core_ext/module/include'

describe Travis::Async do
  before :each do
    Travis::Async.enabled = true
  end

  after :each do
    Travis::Async.enabled = false
    Travis::Async.queues.clear
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

    let(:sleeper) { async_sleep.new }

    it 'processes work in a separate thread, synchronized per queue' do
      1.upto(5) do
        sleeper.sleep_in_queue_1(0.2)
      end

      sleep(0.05)
      sleeper.done[1].should == 0

      1.upto(5) do |ix|
        sleep(0.2)
        sleeper.done[1].should == ix
      end
    end

    it 'processes work in a separate thread, asynchronous in multiple queues' do
      1.upto(5) { |queue| sleeper.send(:"sleep_in_queue_#{queue}", 0.5) }

      sleep(0.05)
      sleeper.total_done.should == 0

      sleep(0.7)
      sleeper.total_done.should == 5
    end
  end

  describe 'when not defining a queue' do
    let(:async_object) do
      Class.new do
        extend Travis::Async
        def self.name; 'Class' end
        def async_method; end
        async :async_method
      end
    end

    it "uses the given object's class name as queue name" do
      async_object.new.async_method
      Travis::Async.queues.keys.should == ['Class']
    end

    it 'queues the method call' do
      async_object.new.async_method
      Travis::Async.queues['Class'].items.size.should == 1
    end
  end

  describe 'Travis::Async.enabled' do
    let(:async_object) do
      Class.new do
        extend Travis::Async
        def async_method; end
        async :async_method
      end
    end

    it 'enables queueing' do
      Travis::Async.enabled = true
      async_object.new.async_method
      Travis::Async.queues.should_not be_empty
    end

    it 'disables queueing' do
      Travis::Async.enabled = false
      async_object.new.async_method
      Travis::Async.queues.should be_empty
    end
  end
end



