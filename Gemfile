source :rubygems

gem 'activesupport',   '~> 3.1.3'
gem 'hashr',           '~> 0.0.18'
gem 'multi_json',      '~> 1.0.3'
gem 'json'

platform :mri do
  gem 'amq-client',    '>= 0.9.0'
  gem 'amqp',          '>= 0.9.0'
end

platform :jruby do
  gem 'hot_bunnies',   '~> 1.3.4'
  gem 'net-ssh-shell', '~> 0.2.0'
  gem 'jruby-openssl', '~> 0.7.4'
end

group :test do
  gem 'rake',          '~> 0.9.2'
  gem 'mocha'
  gem 'rspec'
  gem 'simplecov',     '>= 0.4.0', :require => false
  gem 'activerecord'
end


