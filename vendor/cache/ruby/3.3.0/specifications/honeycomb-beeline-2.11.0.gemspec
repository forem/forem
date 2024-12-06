# -*- encoding: utf-8 -*-
# stub: honeycomb-beeline 2.11.0 ruby lib

Gem::Specification.new do |s|
  s.name = "honeycomb-beeline".freeze
  s.version = "2.11.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "homepage_uri" => "https://honeycomb.io", "source_code_uri" => "https://github.com/honeycombio/beeline-ruby" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Martin Holman".freeze]
  s.bindir = "exe".freeze
  s.date = "2022-06-01"
  s.email = ["martin@honeycomb.io".freeze]
  s.homepage = "https://honeycomb.io".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Instrument your Ruby apps with Honeycomb".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<libhoney>.freeze, [">= 1.14.2".freeze])
  s.add_development_dependency(%q<appraisal>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bump>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<overcommit>.freeze, ["~> 0.46.0".freeze])
  s.add_development_dependency(%q<pry>.freeze, ["< 0.13.0".freeze])
  s.add_development_dependency(%q<pry-byebug>.freeze, ["~> 3.6.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<rspec_junit_formatter>.freeze, [">= 0.5.1".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["< 0.69".freeze])
  s.add_development_dependency(%q<rubocop-performance>.freeze, ["< 1.3.0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<simplecov-console>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<webmock>.freeze, [">= 0".freeze])
end
