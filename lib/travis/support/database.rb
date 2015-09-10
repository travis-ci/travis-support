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
      def connect(env = nil, config = nil)
        env    ||= Travis.config.env
        config ||= Travis.config.database

        ActiveRecord::Base.default_timezone = :utc
        ActiveRecord::Base.logger = Travis.logger
        ActiveRecord::Base.configurations = { env.to_s => config }
        ActiveRecord::Base.establish_connection(Travis.env.to_sym)
      end
    end
  end
end

