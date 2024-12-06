# -*- encoding: utf-8 -*-
# stub: yard-activerecord 0.0.16 ruby lib

Gem::Specification.new do |s|
  s.name = "yard-activerecord".freeze
  s.version = "0.0.16".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Theodor Tonum".freeze]
  s.date = "2016-01-11"
  s.description = "\n    YARD-Activerecord is a YARD extension that handles and interprets methods\n    used when developing applications with ActiveRecord. The extension handles\n    attributes, associations, delegates and scopes. A must for any Rails app\n    using YARD as documentation plugin. ".freeze
  s.email = ["theodor@tonum.no".freeze]
  s.homepage = "https://github.com/theodorton/yard-activerecord".freeze
  s.licenses = ["MIT License".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "ActiveRecord Handlers for YARD".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<yard>.freeze, [">= 0.8.3".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
end
