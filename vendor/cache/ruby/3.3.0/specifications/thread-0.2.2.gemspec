# -*- encoding: utf-8 -*-
# stub: thread 0.2.2 ruby lib

Gem::Specification.new do |s|
  s.name = "thread".freeze
  s.version = "0.2.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["meh.".freeze]
  s.date = "2015-07-17"
  s.description = "Includes a thread pool, message passing capabilities, a recursive mutex, promise, future and delay.".freeze
  s.email = ["meh@schizofreni.co".freeze]
  s.homepage = "http://github.com/meh/ruby-thread".freeze
  s.licenses = ["WTFPL".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Various extensions to the base thread library.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
end
