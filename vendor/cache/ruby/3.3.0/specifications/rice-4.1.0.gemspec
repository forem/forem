# -*- encoding: utf-8 -*-
# stub: rice 4.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rice".freeze
  s.version = "4.1.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/jasonroelofs/rice/issues", "changelog_uri" => "https://github.com/jasonroelofs/rice/blob/master/CHANGELOG.md", "documentation_uri" => "https://jasonroelofs.com/rice", "source_code_uri" => "https://github.com/jasonroelofs/rice" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Paul Brannan".freeze, "Jason Roelofs".freeze, "Charlie Savage".freeze]
  s.date = "2023-04-23"
  s.description = "Rice is a C++ interface to Ruby's C API. It provides a type-safe and\nexception-safe interface in order to make embedding Ruby and writing\nRuby extensions with C++ easier.\n".freeze
  s.email = ["curlypaul924@gmail.com".freeze, "jasonroelofs@gmail.com".freeze, "cfis@savagexi.com".freeze]
  s.extra_rdoc_files = ["README.md".freeze]
  s.files = ["README.md".freeze]
  s.homepage = "https://github.com/jasonroelofs/rice".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Ruby Interface for C++ Extensions".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
end
