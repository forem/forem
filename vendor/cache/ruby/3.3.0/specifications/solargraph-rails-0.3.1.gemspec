# -*- encoding: utf-8 -*-
# stub: solargraph-rails 0.3.1 ruby lib

Gem::Specification.new do |s|
  s.name = "solargraph-rails".freeze
  s.version = "0.3.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Fritz Meissner".freeze]
  s.bindir = "exe".freeze
  s.date = "2022-02-04"
  s.description = "Add reflection on ActiveModel dynamic attributes that will be created at runtime".freeze
  s.email = ["fritz.meissner@gmail.com".freeze]
  s.homepage = "https://github.com/iftheshoefritz/solargraph-rails".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Solargraph plugin that adds Rails-specific code through a Convention".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.2.10".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 12.3.3".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0".freeze])
  s.add_runtime_dependency(%q<solargraph>.freeze, [">= 0.41.1".freeze])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 0".freeze])
end
