# -*- encoding: utf-8 -*-
# stub: zonebie 0.6.1 ruby lib

Gem::Specification.new do |s|
  s.name = "zonebie".freeze
  s.version = "0.6.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andy Lindeman".freeze, "Steven Harman".freeze, "Patrick Van Stee".freeze]
  s.bindir = "exe".freeze
  s.date = "2016-04-13"
  s.description = "Runs your tests in a random timezone".freeze
  s.email = ["andy@andylindeman.com".freeze, "steveharman@gmail.com".freeze, "patrickvanstee@gmail.com".freeze]
  s.homepage = "https://github.com/alindeman/zonebie".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Zonebie prevents bugs in code that deals with timezones by randomly assigning a zone on every run".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.4".freeze])
  s.add_development_dependency(%q<mocha>.freeze, ["~> 0.14.0".freeze])
  s.add_development_dependency(%q<activesupport>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<tzinfo>.freeze, ["~> 1.2".freeze, ">= 1.2.2".freeze])
  s.add_development_dependency(%q<tzinfo-data>.freeze, [">= 1.2016.1".freeze])
end
