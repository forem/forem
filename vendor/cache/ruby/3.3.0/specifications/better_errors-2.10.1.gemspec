# -*- encoding: utf-8 -*-
# stub: better_errors 2.10.1 ruby lib

Gem::Specification.new do |s|
  s.name = "better_errors".freeze
  s.version = "2.10.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/BetterErrors/better_errors/issues", "changelog_uri" => "https://github.com/BetterErrors/better_errors/releases", "source_code_uri" => "https://github.com/BetterErrors/better_errors" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Hailey Somerville".freeze]
  s.date = "2023-06-14"
  s.description = "Provides a better error page for Rails and other Rack apps. Includes source code inspection, a live REPL and local/instance variable inspection for all stack frames.".freeze
  s.email = ["hailey@hailey.lol".freeze]
  s.homepage = "https://github.com/BetterErrors/better_errors".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Better error page for Rails and other Rack apps".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, ["~> 10.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.5".freeze])
  s.add_development_dependency(%q<rspec-html-matchers>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec-its>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<yard>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<sassc>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<kramdown>.freeze, ["> 2.0.0".freeze])
  s.add_runtime_dependency(%q<erubi>.freeze, [">= 1.0.0".freeze])
  s.add_runtime_dependency(%q<rouge>.freeze, [">= 1.0.0".freeze])
  s.add_runtime_dependency(%q<rack>.freeze, [">= 0.9.0".freeze])
end
