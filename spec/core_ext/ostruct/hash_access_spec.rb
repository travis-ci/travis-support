# frozen_string_literal: true

require 'spec_helper'
require 'core_ext/ostruct/hash_access'

describe 'ostruct hash access' do
  let(:struct) { OpenStruct.new(foo: 'foo') }

  it 'allows to read ostruct members using hash access []' do
    struct[:foo].should == 'foo'
  end

  it 'allows to write ostruct members using hash access []=' do
    struct.bar = 'bar'
    struct[:bar].should == 'bar'
  end
end
