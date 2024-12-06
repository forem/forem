# -*- encoding: utf-8 -*-
# stub: fakeredis 0.8.0 ruby lib

Gem::Specification.new do |s|
  s.name = "fakeredis".freeze
  s.version = "0.8.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Guillermo Iguaran".freeze]
  s.date = "2020-03-04"
  s.description = "Fake (In-memory) driver for redis-rb. Useful for testing environment and machines without Redis.".freeze
  s.email = ["guilleiguaran@gmail.com".freeze]
  s.homepage = "https://guilleiguaran.github.com/fakeredis".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Fake (In-memory) driver for redis-rb.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<redis>.freeze, ["~> 4.1".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0".freeze])
end
