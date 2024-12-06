# -*- encoding: utf-8 -*-
# stub: backport 1.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "backport".freeze
  s.version = "1.2.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Fred Snyder".freeze]
  s.date = "2021-06-13"
  s.email = ["fsnyder@castwide.com".freeze]
  s.homepage = "http://github.com/castwide/backport".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.1".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "A pure Ruby library for event-driven IO".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, ["~> 10.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.14".freeze])
end
