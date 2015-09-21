if RUBY_PLATFORM != 'java'
  describe "Bunny AMQP Config" do
    it "converts :username in the config to :user" do
      Travis::Amqp.config = { :username => 'user' }
      expect(Travis::Amqp.config).to eql(:user => 'user')
    end

    it "converts :password in the config to :pass" do
      Travis::Amqp.config = { :password => 'password' }
      expect(Travis::Amqp.config).to eql(:pass => 'password')
    end

    it "converts a string tls value to a boolean" do
      Travis::Amqp.config = { :tls => 'yep' }
      expect(Travis::Amqp.config).to eql(:ssl => true, :tls => true)
    end
  end
end
