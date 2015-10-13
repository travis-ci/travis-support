require 'uri'

module Travis
  module Logging
    class Url < Struct.new(:url)
      def strip_secrets
        uri = URI.parse(url)
        uri.password = '(secret)'          if uri.password
        uri.query = strip_query(uri.query) if uri.query
        uri.to_s
      end

      private

        def strip_query(query)
          query.gsub(/(token|secret|password)=\w*/) { "#{$1}=[secret]" }
        end
    end
  end
end
