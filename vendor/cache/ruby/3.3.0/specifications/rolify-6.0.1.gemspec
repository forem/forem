# -*- encoding: utf-8 -*-
# stub: rolify 6.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "rolify".freeze
  s.version = "6.0.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Florent Monbillard".freeze, "Wellington Cordeiro".freeze]
  s.date = "2023-02-02"
  s.description = "Very simple Roles library without any authorization enforcement supporting scope on resource objects (instance or class). Supports ActiveRecord and Mongoid ORMs.".freeze
  s.email = ["f.monbillard@gmail.com".freeze, "wellington@wellingtoncordeiro.com".freeze]
  s.homepage = "https://github.com/RolifyCommunity/rolify".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Roles library with resource scoping".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<ammeter>.freeze, ["~> 1.1".freeze])
  s.add_development_dependency(%q<appraisal>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 12.3".freeze])
  s.add_development_dependency(%q<rspec-rails>.freeze, ["~> 3.8".freeze])
end
