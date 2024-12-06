# -*- encoding: utf-8 -*-
# stub: nio4r 2.7.0 ruby lib
# stub: ext/nio4r/extconf.rb

Gem::Specification.new do |s|
  s.name = "nio4r".freeze
  s.version = "2.7.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/socketry/nio4r/issues", "changelog_uri" => "https://github.com/socketry/nio4r/blob/main/changes.md", "documentation_uri" => "https://www.rubydoc.info/gems/nio4r/2.6.1", "funding_uri" => "https://github.com/sponsors/ioquatix/", "source_code_uri" => "https://github.com/socketry/nio4r/tree/v2.6.1", "wiki_uri" => "https://github.com/socketry/nio4r/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Tony Arcieri".freeze]
  s.date = "2023-12-01"
  s.description = "Cross-platform asynchronous I/O primitives for scalable network clients and servers. Inspired by the Java NIO API, but simplified for ease-of-use.".freeze
  s.email = ["bascule@gmail.com".freeze]
  s.extensions = ["ext/nio4r/extconf.rb".freeze]
  s.files = ["ext/nio4r/extconf.rb".freeze]
  s.homepage = "https://github.com/socketry/nio4r".freeze
  s.licenses = ["MIT AND (BSD-2-Clause OR GPL-2.0-or-later)".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "New IO for Ruby".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
end
