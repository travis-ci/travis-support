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
      def connect(config = nil)
        ActiveRecord::Base.establish_connection(config || Travis.config.database)
        ActiveRecord::Base.default_timezone = :utc
        ActiveRecord::Base.logger = Travis.logger
      end
    end
  end
end
