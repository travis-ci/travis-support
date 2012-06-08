require 'spec_helper'

describe Travis::Instrumentation do
  let(:klass) do
    Class.new do
      extend Travis::Instrumentation

      def self.name
        'Travis::Foo::Bar'
      end

      def foo(*args)
        'foo'
      end
      instrument :foo
    end
  end

  let(:object) { klass.new }
  let(:timer)  { stub('timer', :update => true) }

  before :each do
    Metriks.stubs(:timer).returns(timer)
  end

  it 'instruments the method' do
    ActiveSupport::Notifications.expects(:instrument).with('bar.foo.travis', :target => object, :args => ['bar'])
    object.foo('bar')
  end

  it 'subscribes to an AS::Notification event' do
    ActiveSupport::Notifications.expects(:subscribe).with('bar.foo.travis')
    object.foo
  end

  it 'meters execution of the method' do
    Metriks.expects(:timer).returns(timer)
    object.foo
  end

  it 'still returns the return value of the instrumented method' do
    object.foo.should == 'foo'
  end
end
