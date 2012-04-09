require 'spec_helper'

if RUBY_PLATFORM != 'java'

  describe "Bunny AMQP Config" do
    it "converts :username in the config to :user" do
      Travis::Amqp.config = { :username => 'user' }
      Travis::Amqp.config.should == { :user => 'user' }
    end

    it "converts :password in the config to :pass" do
      Travis::Amqp.config = { :password => 'password' }
      Travis::Amqp.config.should == { :pass => 'password' }
    end
  end

end
