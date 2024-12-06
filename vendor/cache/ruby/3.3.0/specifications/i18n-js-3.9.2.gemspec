# -*- encoding: utf-8 -*-
# stub: i18n-js 3.9.2 ruby lib

Gem::Specification.new do |s|
  s.name = "i18n-js".freeze
  s.version = "3.9.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nando Vieira".freeze]
  s.date = "2022-03-31"
  s.description = "It's a small library to provide the Rails I18n translations on the Javascript.".freeze
  s.email = ["fnando.vieira@gmail.com".freeze]
  s.homepage = "https://rubygems.org/gems/i18n-js".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.1.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "It's a small library to provide the Rails I18n translations on the Javascript.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<i18n>.freeze, [">= 0.6.6".freeze])
  s.add_development_dependency(%q<appraisal>.freeze, ["~> 2.3".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 12.0".freeze])
  s.add_development_dependency(%q<gem-release>.freeze, [">= 0.7".freeze])
  s.add_development_dependency(%q<coveralls>.freeze, [">= 0.7".freeze])
end
