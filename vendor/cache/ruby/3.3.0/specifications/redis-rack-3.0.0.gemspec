# -*- encoding: utf-8 -*-
# stub: redis-rack 3.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "redis-rack".freeze
  s.version = "3.0.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Luca Guidi".freeze]
  s.date = "2023-12-04"
  s.description = "Redis Store for Rack applications".freeze
  s.email = ["me@lucaguidi.com".freeze]
  s.homepage = "http://redis-store.org/redis-rack".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Redis Store for Rack".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<redis-store>.freeze, ["< 2".freeze, ">= 1.2".freeze])
  s.add_runtime_dependency(%q<rack-session>.freeze, [">= 0.2.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 12.3.3".freeze])
  s.add_development_dependency(%q<bundler>.freeze, ["> 1".freeze, "< 3".freeze])
  s.add_development_dependency(%q<mocha>.freeze, ["~> 0.14.0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5".freeze])
  s.add_development_dependency(%q<connection_pool>.freeze, ["~> 1.2.0".freeze])
end
