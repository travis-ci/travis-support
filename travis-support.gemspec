# encoding: utf-8

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'travis_support/version'

Gem::Specification.new do |s|
  s.name         = 'travis-support'
  s.version      = TravisSupport::VERSION
  s.authors      = ['Sven Fuchs', 'Josh Kalderimis', 'Michael Klishin']
  s.email        = 'contact+travis-support@travis-ci.org'
  s.homepage     = 'http://github.com/travis-ci/travis-support'
  s.summary      = 'Supporting bits for all of Travis.'
  s.description  = s.summary + '  Wow!'
  s.license      = 'MIT'

  s.files         = `git ls-files -z`.split("\x0")
  s.require_paths = %w(lib)
end
