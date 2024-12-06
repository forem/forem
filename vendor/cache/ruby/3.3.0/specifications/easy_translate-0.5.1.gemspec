# -*- encoding: utf-8 -*-
# stub: easy_translate 0.5.1 ruby lib

Gem::Specification.new do |s|
  s.name = "easy_translate".freeze
  s.version = "0.5.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["John Crepezzi".freeze]
  s.date = "2018-01-15"
  s.description = "easy_translate is a wrapper for the google translate API that makes sense programatically, and implements API keys".freeze
  s.email = "john.crepezzi@gmail.com".freeze
  s.homepage = "https://github.com/seejohnrun/easy_translate".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Google Translate API Wrapper for Ruby".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<thread>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<thread_safe>.freeze, [">= 0".freeze])
end
