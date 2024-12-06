# -*- encoding: utf-8 -*-
# stub: stripe-ruby-mock 3.1.0.rc3 ruby lib

Gem::Specification.new do |s|
  s.name = "stripe-ruby-mock".freeze
  s.version = "3.1.0.rc3".freeze

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/stripe-ruby-mock/stripe-ruby-mock/issues", "changelog_uri" => "https://github.com/stripe-ruby-mock/stripe-ruby-mock/blob/master/CHANGELOG.md", "source_code_uri" => "https://github.com/stripe-ruby-mock/stripe-ruby-mock" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Gilbert".freeze]
  s.date = "2021-07-16"
  s.description = "A drop-in library to test stripe without hitting their servers".freeze
  s.email = "gilbertbgarza@gmail.com".freeze
  s.executables = ["stripe-mock-server".freeze]
  s.files = ["bin/stripe-mock-server".freeze]
  s.homepage = "https://github.com/stripe-ruby-mock/stripe-ruby-mock".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "TDD with stripe".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<stripe>.freeze, ["> 5".freeze, "< 6".freeze])
  s.add_runtime_dependency(%q<multi_json>.freeze, ["~> 1.0".freeze])
  s.add_runtime_dependency(%q<dante>.freeze, [">= 0.2.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.7.0".freeze])
  s.add_development_dependency(%q<rubygems-tasks>.freeze, ["~> 0.2".freeze])
  s.add_development_dependency(%q<thin>.freeze, ["~> 1.6.4".freeze])
end
