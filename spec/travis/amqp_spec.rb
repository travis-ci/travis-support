# frozen_string_literal: true

require 'spec_helper'

# ouch, no other tests for amqp at all?

if defined?(JRUBY_VERSION)
  describe Travis::Amqp::Consumer do
    describe 'channel prefetch' do
      let(:consumer)   { described_class.new('queue', options) }
      let(:queue)      { stub('queue', bind: nil, subscribe: nil) }
      let(:channel)    { stub('channel', queue:, :prefetch= => nil) }
      let(:connection) { stub('connection', create_channel: channel) }

      before do
        Travis::Amqp.stubs(:connection).returns(connection)
      end

      describe 'with no options passed' do
        let(:options) { {} }

        it 'defaults to 1' do
          channel.expects(:prefetch=).with(1)
          consumer.subscribe
        end
      end

      describe 'with a prefetch option passed' do
        let(:options)  { { channel: { prefetch: 2 } } }

        it 'uses the given value' do
          channel.expects(:prefetch=).with(2)
          consumer.subscribe
        end
      end
    end
  end
end
