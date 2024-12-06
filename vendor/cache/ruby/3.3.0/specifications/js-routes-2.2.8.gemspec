# -*- encoding: utf-8 -*-
# stub: js-routes 2.2.8 ruby lib

Gem::Specification.new do |s|
  s.name = "js-routes".freeze
  s.version = "2.2.8".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Bogdan Gusiev".freeze]
  s.date = "2023-11-16"
  s.description = "Generates javascript file that defines all Rails named routes as javascript helpers".freeze
  s.email = "agresso@gmail.com".freeze
  s.extra_rdoc_files = ["LICENSE.txt".freeze]
  s.files = ["LICENSE.txt".freeze]
  s.homepage = "http://github.com/railsware/js-routes".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Brings Rails named routes to javascript".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<railties>.freeze, [">= 4".freeze])
  s.add_development_dependency(%q<sprockets-rails>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 3.10.0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.1.0".freeze])
  s.add_development_dependency(%q<appraisal>.freeze, [">= 0.5.2".freeze])
  s.add_development_dependency(%q<bump>.freeze, [">= 0.10.0".freeze])
  s.add_development_dependency(%q<byebug>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<pry-byebug>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<mini_racer>.freeze, [">= 0.4.0".freeze])
end
