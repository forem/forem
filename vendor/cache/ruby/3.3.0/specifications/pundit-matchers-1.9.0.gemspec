# -*- encoding: utf-8 -*-
# stub: pundit-matchers 1.9.0 ruby lib

Gem::Specification.new do |s|
  s.name = "pundit-matchers".freeze
  s.version = "1.9.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Chris Alley".freeze]
  s.date = "2023-04-16"
  s.description = "A set of RSpec matchers for testing Pundit authorisation policies".freeze
  s.email = "chris@chrisalley.info".freeze
  s.homepage = "http://github.com/punditcommunity/pundit-matchers".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "RSpec matchers for Pundit policies".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rspec-rails>.freeze, [">= 3.0.0".freeze])
  s.add_development_dependency(%q<pundit>.freeze, ["~> 1.1".freeze, ">= 1.1.0".freeze])
end
