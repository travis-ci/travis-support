require 'spec_helper'
require 'core_ext/module/include'

describe Travis::Exceptions::Handling do
  let(:klass) do
    Class.new do
      extend Travis::Exceptions::Handling

      attr_reader :called

      def outer
        inner
      end
      rescues :outer

      def inner # so there's something we can stub for raising
        @called = true
      end

      def arity_3(foo, bar, baz)
        [foo, bar, baz]
      end
      rescues :arity_3
    end
  end

  let(:object) { klass.new }

  before do
    Travis.stubs(:env).returns "development"
  end

  it 'calls the original implementation' do
    object.outer
    object.called.should be_true
  end

  it 'rescues exceptions' do
    object.stubs(:inner).raises(Exception)
    lambda { object.outer }.should_not raise_error
  end

  it 'sends exceptions to the exception handler' do
    exception = Exception.new
    object.stubs(:inner).raises(exception)
    Travis::Exceptions.expects(:handle).with(exception, {})
    object.outer
  end

  it 'works with methods that have an arity of 3' do
    object.arity_3(1, 2, 3).should == [1, 2, 3]
  end
end
