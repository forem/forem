# -*- encoding: utf-8 -*-
# stub: sterile 1.0.26 ruby lib

Gem::Specification.new do |s|
  s.name = "sterile".freeze
  s.version = "1.0.26".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Patrick Hogan".freeze]
  s.date = "2024-02-20"
  s.description = "Sterilize your strings! Transliterate, generate slugs, smart format, strip tags, encode/decode entities and more.".freeze
  s.email = ["pbhogan@gmail.com".freeze]
  s.homepage = "https://github.com/pbhogan/sterile".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Sterilize your strings! Transliterate, generate slugs, smart format, strip tags, encode/decode entities and more.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 1.11.7".freeze])
end
