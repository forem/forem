# -*- encoding: utf-8 -*-
# stub: cld3 3.6.0 ruby lib
# stub: ext/cld3/extconf.rb

Gem::Specification.new do |s|
  s.name = "cld3".freeze
  s.version = "3.6.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Akihiko Odaki".freeze]
  s.date = "2023-07-17"
  s.description = "Compact Language Detector v3 (CLD3) is a neural network model for language identification.".freeze
  s.email = "akihiko.odaki@gmail.com".freeze
  s.extensions = ["ext/cld3/extconf.rb".freeze]
  s.files = ["ext/cld3/extconf.rb".freeze]
  s.homepage = "https://github.com/akihikodaki/cld3-ruby".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new([">= 3.0.0".freeze, "< 3.4.0".freeze])
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Compact Language Detector v3 (CLD3)".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rbs>.freeze, ["~> 3.1.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.12.0".freeze])
  s.add_development_dependency(%q<steep>.freeze, ["~> 1.5.0".freeze])
end
