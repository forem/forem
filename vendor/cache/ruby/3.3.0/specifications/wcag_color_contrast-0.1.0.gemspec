# -*- encoding: utf-8 -*-
# stub: wcag_color_contrast 0.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "wcag_color_contrast".freeze
  s.version = "0.1.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mark Dodwell".freeze]
  s.date = "2017-11-13"
  s.email = ["mark@mkdynamic.co.uk".freeze]
  s.homepage = "https://github.com/mkdynamic/wcag_color_contrast".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Calculate the contrast ratio between 2 colors, for checking against the WCAG recommended contrast ratio for legibility.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.3".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
end
