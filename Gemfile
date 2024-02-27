# frozen_string_literal: true

source 'https://rubygems.org'

gem 'activerecord',    '~> 7.0.6'
gem 'activesupport',   '~> 7.0', '>= 7.0.6'
gem 'hashr',           '~> 2.0', '>= 2.0.1'
gem 'json', '~> 2.6', '>= 2.6.3'
gem 'multi_json', '~> 1.15.0'

gem 'metriks'
gem 'sentry-ruby', '~> 5.10'
gem 'sentry-sidekiq'

platform :mri do
  gem 'amq-client',    '>= 1.0.4'
  gem 'amqp',          '>= 1.8.0'
  gem 'bunny',         '>= 2.22.0'
end

platform :jruby do
  gem 'jruby-openssl', '~> 0.8.8'
  gem 'march_hare'
  gem 'net-ssh-shell', '~> 0.2.0'
end

group :test do
  gem 'guard'
  gem 'guard-rspec'
  gem 'mocha', '~> 2.1.0'
  gem 'rake', '>= 13'
  gem 'rspec', '~> 3.12.0'
  gem 'rspec-its', '~> 1.3.0'
  gem 'simplecov', '>= 0.22.0', require: false
end

group :development, :test do
  gem 'rubocop'
  gem 'rubocop-performance'
  gem 'rubocop-rspec'
  gem 'simplecov-console'
end
