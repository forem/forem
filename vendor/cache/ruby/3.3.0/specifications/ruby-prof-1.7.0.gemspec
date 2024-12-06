# -*- encoding: utf-8 -*-
# stub: ruby-prof 1.7.0 ruby lib
# stub: ext/ruby_prof/extconf.rb

Gem::Specification.new do |s|
  s.name = "ruby-prof".freeze
  s.version = "1.7.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/ruby-prof/ruby-prof/issues", "changelog_uri" => "https://github.com/ruby-prof/ruby-prof/blob/master/CHANGES", "documentation_uri" => "https://ruby-prof.github.io/", "source_code_uri" => "https://github.com/ruby-prof/ruby-prof/tree/v1.7.0" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Shugo Maeda, Charlie Savage, Roger Pack, Stefan Kaes".freeze]
  s.date = "2024-01-07"
  s.description = "ruby-prof is a fast code profiler for Ruby. It is a C extension and\ntherefore is many times faster than the standard Ruby profiler. It\nsupports both flat and graph profiles.  For each method, graph profiles\nshow how long the method ran, which methods called it and which\nmethods it called. RubyProf generate both text and html and can output\nit to standard out or to a file.\n".freeze
  s.email = "shugo@ruby-lang.org, cfis@savagexi.com, rogerdpack@gmail.com, skaes@railsexpress.de".freeze
  s.executables = ["ruby-prof".freeze, "ruby-prof-check-trace".freeze]
  s.extensions = ["ext/ruby_prof/extconf.rb".freeze]
  s.files = ["bin/ruby-prof".freeze, "bin/ruby-prof-check-trace".freeze, "ext/ruby_prof/extconf.rb".freeze]
  s.homepage = "https://github.com/ruby-prof/ruby-prof".freeze
  s.licenses = ["BSD-2-Clause".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Fast Ruby profiler".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake-compiler>.freeze, [">= 0".freeze])
end
