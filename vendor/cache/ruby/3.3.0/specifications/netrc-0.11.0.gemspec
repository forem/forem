# -*- encoding: utf-8 -*-
# stub: netrc 0.11.0 ruby lib

Gem::Specification.new do |s|
  s.name = "netrc".freeze
  s.version = "0.11.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Keith Rarick".freeze, "geemus (Wesley Beary)".freeze]
  s.date = "2015-10-29"
  s.description = "This library can read and update netrc files, preserving formatting including comments and whitespace.".freeze
  s.email = "geemus@gmail.com".freeze
  s.homepage = "https://github.com/geemus/netrc".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Library to read and write netrc files.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
end
