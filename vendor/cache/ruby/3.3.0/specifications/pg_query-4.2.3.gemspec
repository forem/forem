# -*- encoding: utf-8 -*-
# stub: pg_query 4.2.3 ruby lib
# stub: ext/pg_query/extconf.rb

Gem::Specification.new do |s|
  s.name = "pg_query".freeze
  s.version = "4.2.3".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Lukas Fittl".freeze]
  s.date = "2023-08-05"
  s.description = "Parses SQL queries using a copy of the PostgreSQL server query parser".freeze
  s.email = "lukas@fittl.com".freeze
  s.extensions = ["ext/pg_query/extconf.rb".freeze]
  s.extra_rdoc_files = ["CHANGELOG.md".freeze, "README.md".freeze]
  s.files = ["CHANGELOG.md".freeze, "README.md".freeze, "ext/pg_query/extconf.rb".freeze]
  s.homepage = "https://github.com/pganalyze/pg_query".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze, "--exclude".freeze, "ext/".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "PostgreSQL query parsing and normalization library".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rake-compiler>.freeze, ["~> 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["= 0.49.1".freeze])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, ["= 1.15.1".freeze])
  s.add_runtime_dependency(%q<google-protobuf>.freeze, [">= 3.22.3".freeze])
end
