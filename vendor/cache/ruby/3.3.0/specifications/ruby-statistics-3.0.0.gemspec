# -*- encoding: utf-8 -*-
# stub: ruby-statistics 3.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ruby-statistics".freeze
  s.version = "3.0.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["esteban zapata".freeze]
  s.bindir = "exe".freeze
  s.date = "2021-10-08"
  s.description = "This gem is intended to accomplish the same purpose as jStat js library:\n                          to provide ruby with statistical capabilities without the need\n                          of a statistical programming language like R or Octave. Some functions\n                          and capabilities are an implementation from other authors and are\n                          referenced properly in the class/method.".freeze
  s.email = ["estebanz01@outlook.com".freeze]
  s.homepage = "https://github.com/estebanz01/ruby-statistics".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "A ruby gem for som specific statistics. Inspired by the jStat js library.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, [">= 12.0.0".freeze, "~> 13.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 3.6.0".freeze])
  s.add_development_dependency(%q<grb>.freeze, ["~> 0.4.1".freeze, ">= 0.4.1".freeze])
  s.add_development_dependency(%q<byebug>.freeze, [">= 9.1.0".freeze])
  s.add_development_dependency(%q<pry>.freeze, [">= 0".freeze])
end
