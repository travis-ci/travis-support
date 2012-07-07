module Travis
  module Helpers
    extend self

    def obfuscate_env_vars(line)
      regex = /(?<=\=)(?:[^'"\=\s]+|(?<q>['"]).*?\k<q>)/
      line.gsub(regex) { |val| '[secure]' }
    end
  end
end
