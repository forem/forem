# -*- encoding: utf-8 -*-
# stub: unaccent 0.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "unaccent".freeze
  s.version = "0.4.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jonian Guveli".freeze]
  s.date = "2022-08-31"
  s.description = "Replace accented characters with unaccented characters.".freeze
  s.email = ["jonian@hardpixel.eu".freeze]
  s.homepage = "https://github.com/hardpixel/unaccent".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Replace accented characters with unaccented characters".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
end
