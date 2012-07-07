require 'spec_helper'
require 'travis/support'

describe Travis::Helpers do
  describe '.obfuscate_env_vars' do
    it 'obfuscates env vars' do
      expected = 'FOO=[secure] BAZ=[secure]'
      Travis::Helpers.obfuscate_env_vars('FOO=bar BAZ=baz').should == expected
    end

    it 'works also with apostrophes' do
      expected = 'FOO=[secure] BAZ=[secure]'
      Travis::Helpers.obfuscate_env_vars('FOO=\'bar\' BAZ="baz"').should == expected
    end
  end
end
