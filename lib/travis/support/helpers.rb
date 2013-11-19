module Travis
  module Helpers
    extend self

    def obfuscate_env_vars(line)
      regex = /(?<=\=)(?:(?<q>['"]).*?[^\\]\k<q>|(.*?)(?= \w+=|$))/
      line.respond_to?(:gsub) ? line.gsub(regex) { |val| '[secure]' } : '[One of the secure variables in your .travis.yml has an invalid format.]'
    end
  end
end
