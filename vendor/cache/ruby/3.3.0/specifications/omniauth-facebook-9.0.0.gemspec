# -*- encoding: utf-8 -*-
# stub: omniauth-facebook 9.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "omniauth-facebook".freeze
  s.version = "9.0.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mark Dodwell".freeze, "Josef \u0160im\u00E1nek".freeze]
  s.date = "2021-10-25"
  s.email = ["mark@madeofcode.com".freeze, "retro@ballgag.cz".freeze]
  s.homepage = "https://github.com/simi/omniauth-facebook".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Facebook OAuth2 Strategy for OmniAuth".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<omniauth-oauth2>.freeze, ["~> 1.2".freeze])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<mocha>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
end
