# -*- encoding: utf-8 -*-
# stub: datadog-ci 0.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "datadog-ci".freeze
  s.version = "0.3.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 2.0.0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "changelog_uri" => "https://github.com/DataDog/datadog-ci-rb/blob/main/CHANGELOG.md", "homepage_uri" => "https://github.com/DataDog/datadog-ci-rb", "source_code_uri" => "https://github.com/DataDog/datadog-ci-rb" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Datadog, Inc.".freeze]
  s.date = "2023-10-25"
  s.description = "  datadog-ci is a Datadog's CI visibility library for Ruby. It traces\n  tests as they are being executed and brings developers visibility into\n  their CI pipelines.\n".freeze
  s.email = ["dev@datadoghq.com".freeze]
  s.homepage = "https://github.com/DataDog/datadog-ci-rb".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.required_ruby_version = Gem::Requirement.new([">= 2.1.0".freeze, "< 3.4".freeze])
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Datadog CI visibility for your ruby application".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<msgpack>.freeze, [">= 0".freeze])
end
