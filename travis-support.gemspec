# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'travis_support/version'

Gem::Specification.new do |s|
  s.name         = "travis-support"
  s.version      = TravisSupport::VERSION
  s.authors      = ['Sven Fuchs', 'Josh Kalderimis', 'Michael Klishin']
  s.email        = 'contact@travis-ci.org'
  s.homepage     = 'http://github.com/travis-ci/travis-support'
  s.summary      = "[summary]"
  s.description  = "[description]"

  s.files        = Dir['{lib/**/*,spec**/*,[A-Z]*}']
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.rubyforge_project = '[none]'
end
