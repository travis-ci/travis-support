source 'https://rubygems.org'

gem 'activerecord',    '~> 7.0.6'
gem 'activesupport',   '~> 7.0', '>= 7.0.6'
gem 'hashr',           '~> 2.0', '>= 2.0.1'
gem 'multi_json'
gem 'json', '~> 2.6', '>= 2.6.3'

gem 'metriks'
gem 'sentry-ruby', '~> 5.10'
gem "sentry-sidekiq"

platform :mri do
  gem 'amq-client',    '>= 0.9.0'
  gem 'amqp',          '>= 0.9.0'
  gem 'bunny',         '>= 0.7.9'
end

platform :jruby do
  gem 'march_hare'
  gem 'net-ssh-shell', '~> 0.2.0'
  gem 'jruby-openssl', '~> 0.8.8'
end

group :test do
  gem 'rake',          '>= 13'
  gem 'mocha',         '~> 1.2', '>= 1.2.1'
  gem 'rspec',         '~> 3.12.0'
  gem 'rspec-its',     '~> 1.3.0'
  gem 'simplecov',     '>= 0.4.0', :require => false
  gem 'guard'
  gem 'guard-rspec'
end
