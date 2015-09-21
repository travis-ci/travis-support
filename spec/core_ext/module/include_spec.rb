require 'core_ext/module/include'

describe 'Inclusion of anonymous modules' do
  it 'includes an anonymous module defined by the given block' do
    object = Class.new { include { def foo; 'foo'; end } }.new
    expect(object.foo).to eq('foo')
  end
end
