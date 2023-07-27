require 'spec_helper'
require 'core_ext/module/include'

describe 'Inclusion of anonymous modules' do
  it 'includes an anonymous module defined by the given block' do
    object = Class.new do
      include do
        def foo
          'foo'
        end
      end
    end.new
    object.foo.should == 'foo'
  end
end
