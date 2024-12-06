# -*- encoding: utf-8 -*-
# stub: guard-rspec 4.7.3 ruby lib

Gem::Specification.new do |s|
  s.name = "guard-rspec".freeze
  s.version = "4.7.3".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Thibaud Guillaume-Gentil".freeze]
  s.date = "2016-07-29"
  s.description = "Guard::RSpec automatically run your specs (much like autotest).".freeze
  s.email = "thibaud@thibaud.gg".freeze
  s.homepage = "https://github.com/guard/guard-rspec".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Guard gem for RSpec".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<guard>.freeze, ["~> 2.1".freeze])
  s.add_runtime_dependency(%q<guard-compat>.freeze, ["~> 1.1".freeze])
  s.add_runtime_dependency(%q<rspec>.freeze, [">= 2.99.0".freeze, "< 4.0".freeze])
end
