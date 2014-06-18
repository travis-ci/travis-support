require 'rubygems'

require 'rspec'
require 'rspec/its'
require 'mocha'

require 'logger'
require 'stringio'
require 'travis/support'
require 'travis/support/amqp'

RSpec.configure do |config|
  config.mock_with :mocha

  config.before :each do
    Travis.logger = Logger.new(StringIO.new)
  end
end
