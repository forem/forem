# -*- encoding: utf-8 -*-
# stub: fog-xml 0.1.4 ruby lib

Gem::Specification.new do |s|
  s.name = "fog-xml".freeze
  s.version = "0.1.4".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Wesley Beary (geemus)".freeze, "Paul Thornthwaite (tokengeek)".freeze, "The fog team".freeze]
  s.date = "2021-10-01"
  s.description = "Extraction of the XML parsing tools shared between a\n                          number of providers in the 'fog' gem".freeze
  s.email = ["geemus@gmail.com".freeze, "tokengeek@gmail.com".freeze]
  s.homepage = "https://github.com/fog/fog-xml".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "XML parsing for fog providers".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<fog-core>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 1.5.11".freeze, "< 2.0.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<turn>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<pry>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<coveralls>.freeze, [">= 0".freeze])
end
