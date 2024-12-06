# -*- encoding: utf-8 -*-
# stub: smart_properties 1.17.0 ruby lib

Gem::Specification.new do |s|
  s.name = "smart_properties".freeze
  s.version = "1.17.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "source_code_uri" => "https://github.com/t6d/smart_properties" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Konstantin Tennhard".freeze]
  s.date = "2021-12-16"
  s.description = "  SmartProperties are a more flexible and feature-rich alternative to\n  traditional Ruby accessors. They provide support for input conversion,\n  input validation, specifying default values and presence checking.\n".freeze
  s.email = ["me@t6d.de".freeze]
  s.homepage = "".freeze
  s.rubygems_version = "3.5.3".freeze
  s.summary = "SmartProperties \u2013 Ruby accessors on steroids".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
  s.add_development_dependency(%q<pry>.freeze, [">= 0".freeze])
end
