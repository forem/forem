# -*- encoding: utf-8 -*-
# stub: sidekiq 6.5.12 ruby lib

Gem::Specification.new do |s|
  s.name = "sidekiq".freeze
  s.version = "6.5.12".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/mperham/sidekiq/issues", "changelog_uri" => "https://github.com/mperham/sidekiq/blob/main/Changes.md", "documentation_uri" => "https://github.com/mperham/sidekiq/wiki", "homepage_uri" => "https://sidekiq.org", "source_code_uri" => "https://github.com/mperham/sidekiq" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mike Perham".freeze]
  s.date = "2023-10-10"
  s.description = "Simple, efficient background processing for Ruby.".freeze
  s.email = ["mperham@gmail.com".freeze]
  s.executables = ["sidekiq".freeze, "sidekiqmon".freeze]
  s.files = ["bin/sidekiq".freeze, "bin/sidekiqmon".freeze]
  s.homepage = "https://sidekiq.org".freeze
  s.licenses = ["LGPL-3.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Simple, efficient background processing for Ruby".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<redis>.freeze, ["< 5".freeze, ">= 4.5.0".freeze])
  s.add_runtime_dependency(%q<connection_pool>.freeze, ["< 3".freeze, ">= 2.2.5".freeze])
  s.add_runtime_dependency(%q<rack>.freeze, ["~> 2.0".freeze])
end
