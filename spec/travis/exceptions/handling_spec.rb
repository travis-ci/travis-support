require 'core_ext/module/include'
require 'travis/support/exceptions'

describe Travis::Exceptions::Handling do
  let(:klass) do
    options = self.options

    Class.new do
      extend Travis::Exceptions::Handling

      attr_reader :called

      def outer
        inner
      end
      rescues :outer, options

      def inner # so there's something we can stub for raising
        @called = true
      end

      def arity_3(foo, bar, baz)
        [foo, bar, baz]
      end
      rescues :arity_3
    end
  end

  let(:options) { {} }
  let(:object)  { klass.new }

  before do
    Travis.stubs(:env).returns 'development'
  end

  it 'calls the original implementation' do
    object.outer
    expect(object.called).to eq(true)
  end

  it 'rescues exceptions' do
    object.stubs(:inner).raises(Exception)
    expect { object.outer }.to_not raise_error
  end

  it 'sends exceptions to the exception handler' do
    exception = Exception.new
    object.stubs(:inner).raises(exception)
    Travis::Exceptions.expects(:handle).with(exception, {})
    object.outer
  end

  it 'works with methods that have an arity of 3' do
    expect(object.arity_3(1, 2, 3)).to eq([1, 2, 3])
  end

  describe '' do
    let(:error)   { Class.new(StandardError) }
    let(:options) { { raise: error } }

    it '' do
      object.stubs(:inner).raises(error)
      expect { object.outer }.to raise_error(error)
    end
  end
end
