# frozen_string_literal: true

module Travis
  module Helpers
    module_function

    def obfuscate_env_vars(line)
      regex = /(?<=\=)(?:(?<q>['"]).*?[^\\]\k<q>|(.*?)(?= \w+=|$))/
      if line.respond_to?(:gsub)
        line.gsub(regex) do |_val|
          '[secure]'
        end
      else
        '[One of the secure variables in your .travis.yml has an invalid format.]'
      end
    end
  end
end
