# -*- encoding: utf-8 -*-
# stub: strong_migrations 1.7.0 ruby lib

Gem::Specification.new do |s|
  s.name = "strong_migrations".freeze
  s.version = "1.7.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andrew Kane".freeze, "Bob Remeika".freeze, "David Waller".freeze]
  s.date = "2024-01-05"
  s.email = ["andrew@ankane.org".freeze, "bob.remeika@gmail.com".freeze]
  s.homepage = "https://github.com/ankane/strong_migrations".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Catch unsafe migrations in development".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 5.2".freeze])
end
