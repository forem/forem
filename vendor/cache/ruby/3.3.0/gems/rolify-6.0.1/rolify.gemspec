# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'rolify/version'

Gem::Specification.new do |s|
  s.name        = 'rolify'
  s.summary     = %q{Roles library with resource scoping}
  s.description = %q{Very simple Roles library without any authorization enforcement supporting scope on resource objects (instance or class). Supports ActiveRecord and Mongoid ORMs.}
  s.version     = Rolify::VERSION
  s.platform    = Gem::Platform::RUBY
  s.homepage    = 'https://github.com/RolifyCommunity/rolify'

  s.license     = 'MIT'

  s.authors     = [
    'Florent Monbillard',
    'Wellington Cordeiro'
  ]
  s.email       = [
    'f.monbillard@gmail.com',
    'wellington@wellingtoncordeiro.com'
  ]

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 2.5'

  s.add_development_dependency 'ammeter',     '~> 1.1' # Spec generator
  s.add_development_dependency 'appraisal',   '~> 2.0'
  s.add_development_dependency 'bundler',     '~> 2.0' # packaging feature
  s.add_development_dependency 'rake',        '~> 12.3' # Tasks manager
  s.add_development_dependency 'rspec-rails', '~> 3.8'
end
