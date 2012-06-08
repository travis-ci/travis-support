require 'spec_helper'

describe Travis::Instrumentation do
  let(:klass) do
    Class.new do
      extend Travis::Instrumentation

      def self.name
        'Travis::Foo::Bar'
      end

      def call(*args)
        'call'
      end
      instrument :call
    end
  end

  let(:object) { klass.new }
  let(:timer)  { stub('timer', :update => true) }

  before :each do
    Metriks.stubs(:timer).returns(timer)
  end

  it 'instruments the method' do
    ActiveSupport::Notifications.expects(:instrument).with('call.bar.foo.travis', :target => object, :args => ['foo'])
    object.call('foo')
  end

  it 'subscribes to AS::Notification events on this class and namespaced classes' do
    ActiveSupport::Notifications.expects(:subscribe).with(/^call\.(.*\.)?bar.foo.travis$/)
    object.call
  end

  it 'meters execution of the method' do
    Metriks.expects(:timer).returns(timer)
    object.call
  end

  it 'still returns the return value of the instrumented method' do
    object.call.should == 'call'
  end
end
