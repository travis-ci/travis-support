require 'spec_helper'
require 'travis/support'

describe Travis::Assertions do
  class A
    extend Travis::Assertions

    def initialize(result)
      @result = result
    end

    def the_method
      @result
    end
    assert :the_method

    def the_method_with_description
      @result
    end
    assert :the_method_with_description, 'Must have an awesome Truth value'
  end

  describe 'assertion with no description' do
    subject { lambda { A.new(@return_value).the_method } }

    it 'does not raise an exception when the returned value is true' do
      @return_value = true
      should_not raise_error
    end

    it 'raises an exception when the returned value is false' do
      @return_value = false
      should raise_error(Travis::AssertionFailed, /did not return true/)
    end
  end

  describe 'assertion with a description' do
    subject { lambda { A.new(@return_value).the_method_with_description } }

    it 'does not raise an exception when the returned value is true' do
      @return_value = true
      should_not raise_error
    end

    it 'raises an exception when the returned value is false' do
      @return_value = false
      should raise_error(Travis::AssertionFailed, 'Must have an awesome Truth value')
    end
  end
end
