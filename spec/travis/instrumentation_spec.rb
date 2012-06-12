require 'spec_helper'

describe Travis::Instrumentation do
  let(:klass) do
    Class.new do
      extend Travis::Instrumentation

      def self.name
        'Travis::Foo::Bar'
      end

      def tracked(*args)
        inner
      end
      instrument :tracked, :scope => :scope, :track => true

      def inner
        'result'
      end

      def scope
        'baz'
      end
    end
  end

  let(:object) { klass.new }
  let(:timer)  { stub('timer', :update => true) }

  before :each do
    Metriks.stubs(:timer).returns(timer)
  end

  it 'instruments the method' do
    ActiveSupport::Notifications.expects(:instrument).with('travis.foo.bar.baz.tracked:call', :target => object, :args => ['foo'])
    object.tracked('foo')
  end

  describe 'subscriptions' do
    before :each  do
      ActiveSupport::Notifications.stubs(:subscribe)
    end

    it 'subscribes to AS::Notification events on this class and namespaced classes' do
      ActiveSupport::Notifications.expects(:subscribe)
      object.tracked
    end
  end

  describe 'calling the method' do
    it 'meters execution of the method' do
      Metriks.expects(:timer).with('travis.foo.bar.baz.tracked:call').returns(timer)
      object.tracked
    end

    it 'still returns the return value of the instrumented method' do
      object.tracked.should == 'result'
    end
  end

  describe 'tracking' do
    let(:meter) { stub('meter', :mark => true) }

    describe 'publishes ActiveSupport::Notification events' do
      before :each do
        ActiveSupport::Notifications.stubs(:publish)
      end

      it 'about the method receive event' do
        ActiveSupport::Notifications.expects(:publish).with('travis.foo.bar.baz.tracked:received', :target => object, :args => [])
        object.tracked
      end

      it 'about the method complete event' do
        ActiveSupport::Notifications.expects(:publish).with('travis.foo.bar.baz.tracked:completed', :target => object, :args => [])
        object.tracked
      end

      it 'about the method failed event' do
        object.stubs(:inner).raises(StandardError)
        ActiveSupport::Notifications.expects(:publish).with('travis.foo.bar.baz.tracked:failed', :target => object, :args => [])
        object.tracked rescue nil
      end

      it 'reraises the exception from the failed method call' do
        object.stubs(:inner).raises(StandardError)
        lambda { object.tracked }.should raise_error(StandardError)
      end
    end

    describe 'meters events' do
      before(:each) do
        Metriks.stubs(:meter).returns(meter)
      end

      it 'tracks the that the method call is received' do
        Metriks.expects(:meter).with('travis.foo.bar.baz.tracked:received').returns(meter)
        object.tracked
      end

      it 'tracks the that the method call is completed' do
        Metriks.expects(:meter).with('travis.foo.bar.baz.tracked:completed').returns(meter)
        object.tracked
      end

      it 'tracks the that the method call has failed' do
        object.stubs(:inner).raises(StandardError)
        Metriks.expects(:meter).with('travis.foo.bar.baz.tracked:failed').returns(meter)
        object.tracked rescue nil
      end
    end
  end
end
