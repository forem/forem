# -*- encoding: utf-8 -*-
# stub: redis-store 1.10.0 ruby lib

Gem::Specification.new do |s|
  s.name = "redis-store".freeze
  s.version = "1.10.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Luca Guidi".freeze]
  s.date = "2023-09-11"
  s.description = "Namespaced Rack::Session, Rack::Cache, I18n and cache Redis stores for Ruby web frameworks.".freeze
  s.email = ["me@lucaguidi.com".freeze]
  s.homepage = "http://redis-store.org/redis-store".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Redis stores for Ruby frameworks".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<redis>.freeze, [">= 4".freeze, "< 6".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 12.3.3".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<mocha>.freeze, ["~> 2.1.0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5".freeze])
  s.add_development_dependency(%q<git>.freeze, ["~> 1.2".freeze])
  s.add_development_dependency(%q<pry-nav>.freeze, ["~> 0.2.4".freeze])
  s.add_development_dependency(%q<pry>.freeze, ["~> 0.10.4".freeze])
  s.add_development_dependency(%q<redis-store-testing>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<appraisal>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.54".freeze])
end
