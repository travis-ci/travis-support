require 'spec_helper'
require 'travis/support'

describe Travis::Helpers do
  describe '.obfuscate_env_vars' do
    it 'works in single var' do
      expected = 'FOO=[secure]'
      Travis::Helpers.obfuscate_env_vars('FOO=bar').should == expected
    end

    it 'obfuscates env vars' do
      expected = 'FOO=[secure] BAZ=[secure]'
      Travis::Helpers.obfuscate_env_vars('FOO=bar BAZ=baz').should == expected
    end

    it 'works also with apostrophes' do
      expected = 'FOO=[secure] BAZ=[secure]'
      Travis::Helpers.obfuscate_env_vars('FOO=\'bar\' BAZ="baz"').should == expected
    end

    it 'works with spaces' do
      expected = 'FOO=[secure] BAR=[secure]'
      Travis::Helpers.obfuscate_env_vars('FOO=a b c BAR=d').should == expected
    end

    it 'works correctly if something looking as a var is inside other var\'s value' do
      expected = 'FOO=[secure] BAR=[secure]'
      Travis::Helpers.obfuscate_env_vars('FOO="BAZ=d" BAR=d').should == expected
    end

    it 'works with escaped quote or double quote' do
      expected = 'FOO=[secure] BAR=[secure]'
      Travis::Helpers.obfuscate_env_vars('FOO="BAZ=\"d\"" BAR=d').should == expected
    end

    it 'works with empty quoted string' do
      expected = 'FOO=[secure] BAR=[secure]'
      Travis::Helpers.obfuscate_env_vars('FOO="" BAR=d').should == expected
    end

    it "doesn't fail on lines that are hashes" do
      Travis::Helpers.obfuscate_env_vars("SOMEKEY=value" => nil).should == '[One of the secure variables in your .travis.yml has an invalid format.]'
    end
  end
end
