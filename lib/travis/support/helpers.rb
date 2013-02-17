module Travis
  module Helpers
    extend self

    def obfuscate_env_vars(line)
      regex = /(?<=\=)(?:(?<q>['"]).*?[^\\]\k<q>|(.*?)(?= \w+=|$))/
      line.gsub(regex) { |val| '[secure]' }
    end
  end
end
