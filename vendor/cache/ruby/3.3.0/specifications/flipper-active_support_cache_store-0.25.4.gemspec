# -*- encoding: utf-8 -*-
# stub: flipper-active_support_cache_store 0.25.4 ruby lib

Gem::Specification.new do |s|
  s.name = "flipper-active_support_cache_store".freeze
  s.version = "0.25.4".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/jnunemaker/flipper/blob/master/Changelog.md" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["John Nunemaker".freeze]
  s.date = "2022-11-07"
  s.email = ["nunemaker@gmail.com".freeze]
  s.homepage = "https://github.com/jnunemaker/flipper".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "ActiveSupport::Cache store adapter for Flipper".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<flipper>.freeze, ["~> 0.25.4".freeze])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 4.2".freeze, "< 8".freeze])
end
