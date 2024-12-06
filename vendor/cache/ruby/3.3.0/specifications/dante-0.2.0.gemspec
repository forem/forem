# -*- encoding: utf-8 -*-
# stub: dante 0.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "dante".freeze
  s.version = "0.2.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nathan Esquenazi".freeze]
  s.date = "2013-12-04"
  s.description = "Turn any process into a demon.".freeze
  s.email = ["nesquena@gmail.com".freeze]
  s.homepage = "https://github.com/bazaarlabs/dante".freeze
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Turn any process into a demon".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<mocha>.freeze, [">= 0".freeze])
end
