# -*- encoding: utf-8 -*-
# stub: coffee-script 2.4.1 ruby lib

Gem::Specification.new do |s|
  s.name = "coffee-script".freeze
  s.version = "2.4.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jeremy Ashkenas".freeze, "Joshua Peek".freeze, "Sam Stephenson".freeze]
  s.date = "2015-04-06"
  s.description = "    Ruby CoffeeScript is a bridge to the JS CoffeeScript compiler.\n".freeze
  s.email = "josh@joshpeek.com".freeze
  s.homepage = "http://github.com/josh/ruby-coffee-script".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Ruby CoffeeScript Compiler".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<coffee-script-source>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<execjs>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<json>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
end
