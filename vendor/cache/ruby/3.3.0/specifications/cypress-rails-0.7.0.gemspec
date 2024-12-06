# -*- encoding: utf-8 -*-
# stub: cypress-rails 0.7.0 ruby lib

Gem::Specification.new do |s|
  s.name = "cypress-rails".freeze
  s.version = "0.7.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Justin Searls".freeze]
  s.bindir = "exe".freeze
  s.date = "2024-02-13"
  s.email = ["searls@gmail.com".freeze]
  s.executables = ["cypress-rails".freeze]
  s.files = ["exe/cypress-rails".freeze]
  s.homepage = "https://github.com/testdouble/cypress-rails".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Helps you write Cypress tests of your Rails app".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<railties>.freeze, [">= 5.2.0".freeze])
  s.add_runtime_dependency(%q<puma>.freeze, [">= 3.8.0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0".freeze])
  s.add_development_dependency(%q<standard>.freeze, [">= 0.2.0".freeze])
end
