require 'spec_helper'
require 'core_ext/module/include'

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
        async :async_method
      end
    end

    it "uses the given object's class name as queue name" do
      async_object.new.async_method
      Travis::Async::Threaded.queues.keys.should == ['Class']
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
      Travis::Async::Threaded.queues.should_not be_empty
    end

    it 'disables queueing' do
      Travis::Async.enabled = false
      async_object.new.async_method
      Travis::Async::Threaded.queues.should be_empty
    end
  end
end



