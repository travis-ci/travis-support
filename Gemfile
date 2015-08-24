source 'https://rubygems.org'

gem 'activerecord',    '~> 3.2.12'
gem 'activesupport',   '~> 3.2.12'
gem 'hashr',           '~> 0.0.20'
gem 'multi_json'
gem 'json',            '~> 1.8.3'
gem 'gem-patching'

gem 'metriks',         :git => 'https://github.com/roidrage/metriks.git', :ref => 'source'
gem 'sentry-raven',    :github => 'getsentry/raven-ruby'

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
  gem 'rake',          '~> 0.9.2'
  gem 'mocha',         '~> 0.11.0'
  gem 'rspec',         '~> 2.14'
  gem 'rspec-its',     '~> 1.0.1'
  gem 'simplecov',     '>= 0.4.0', :require => false
  gem 'guard'
  gem 'guard-rspec'
end


