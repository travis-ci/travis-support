require 'spec_helper'
require 'core_ext/module/include'

class InstrumentableMock
  extend Travis::NewRelic

  attr_reader :handled

  def handle
    @handled = true
  end
  new_relic :handle, :category => :task
end

class NewRelicMock
  attr_reader :args

  def perform_action_with_newrelic_trace(*args)
    @args = args
    yield
  end
end

describe Travis::NewRelic do
  describe 'instrumentation' do
    let(:instrumentable) { InstrumentableMock.new }
    let(:new_relic)      { NewRelicMock.new }

    before :each do
      Travis::NewRelic.stubs(:started?).returns(true)
      Travis::NewRelic.stubs(:proxy).returns(new_relic)
    end

    it 'still calls the instrumented method' do
      instrumentable.handle
      instrumentable.handled.should be_true
    end

    it 'notifies new relic with the expected payload' do
      instrumentable.handle
      new_relic.args.should == [{ :class_name => 'InstrumentableMock', :name => 'handle', :category => :task }]
    end
  end
end
