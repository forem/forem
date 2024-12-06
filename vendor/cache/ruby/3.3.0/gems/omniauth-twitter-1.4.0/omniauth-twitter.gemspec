# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "omniauth-twitter/version"

Gem::Specification.new do |s|
  s.name        = "omniauth-twitter"
  s.version     = OmniAuth::Twitter::VERSION
  s.authors     = ["Arun Agrawal"]
  s.email       = ["arunagw@gmail.com"]
  s.homepage    = "https://github.com/arunagw/omniauth-twitter"
  s.description = %q{OmniAuth strategy for Twitter}
  s.summary     = s.description
  s.license     = "MIT"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new('>= 1.9.3')
  s.add_dependency 'omniauth-oauth', '~> 1.1'
  s.add_dependency 'rack'
  s.add_development_dependency 'bundler', '~> 1.0'
end
