begin
  require 'active_record'
  require 'erb'
rescue LoadError
end

# Encapsulates setting up ActiveRecord and connecting to the database as
# required for travis-hub, which is a non-rails app.
module Travis
  module Database
    class << self
      def connect
        ActiveRecord::Base.default_timezone = :utc
        ActiveRecord::Base.logger = Travis.logger
        ActiveRecord::Base.establish_connection(Travis.config.database)
      end
    end
  end
end
