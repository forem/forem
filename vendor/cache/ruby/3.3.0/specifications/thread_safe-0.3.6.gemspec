# -*- encoding: utf-8 -*-
# stub: thread_safe 0.3.6 ruby lib

Gem::Specification.new do |s|
  s.name = "thread_safe".freeze
  s.version = "0.3.6".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Charles Oliver Nutter".freeze, "thedarkone".freeze]
  s.date = "2017-02-22"
  s.description = "A collection of data structures and utilities to make thread-safe programming in Ruby easier".freeze
  s.email = ["headius@headius.com".freeze, "thedarkone2@gmail.com".freeze]
  s.homepage = "https://github.com/ruby-concurrency/thread_safe".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Thread-safe collections and utilities for Ruby".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<atomic>.freeze, ["= 1.1.16".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["< 12.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.2".freeze])
end
