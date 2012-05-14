source :rubygems

gem 'activesupport',   '~> 3.2.1'
gem 'hashr',           '~> 0.0.20'
gem 'multi_json'
gem 'json'
gem 'gem-patching'

gem 'metriks',         :git => 'git://github.com/mattmatt/metriks', :ref => 'source'

platform :mri do
  gem 'amq-client',    '>= 0.9.0'
  gem 'amqp',          '>= 0.9.0'
  gem 'bunny',         '>= 0.7.9'
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


