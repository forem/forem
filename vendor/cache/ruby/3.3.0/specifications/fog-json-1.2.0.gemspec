# -*- encoding: utf-8 -*-
# stub: fog-json 1.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "fog-json".freeze
  s.version = "1.2.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Wesley Beary (geemus)".freeze, "Paul Thornthwaite (tokengeek)".freeze, "The fog team".freeze]
  s.date = "2018-06-22"
  s.description = "Extraction of the JSON parsing tools shared between a\n                          number of providers in the 'fog' gem.".freeze
  s.email = ["geemus@gmail.com".freeze, "tokengeek@gmail.com".freeze]
  s.homepage = "http://github.com/fog/fog-json".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "JSON parsing for fog providers".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<fog-core>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<multi_json>.freeze, ["~> 1.10".freeze])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.5".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
end
