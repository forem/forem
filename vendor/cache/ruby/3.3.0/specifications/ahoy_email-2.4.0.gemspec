# -*- encoding: utf-8 -*-
# stub: ahoy_email 2.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ahoy_email".freeze
  s.version = "2.4.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andrew Kane".freeze]
  s.date = "2024-11-11"
  s.email = "andrew@ankane.org".freeze
  s.homepage = "https://github.com/ankane/ahoy_email".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "First-party email analytics for Rails".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<actionmailer>.freeze, [">= 7".freeze])
  s.add_runtime_dependency(%q<addressable>.freeze, [">= 2.3.2".freeze])
  s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<safely_block>.freeze, [">= 0.4".freeze])
end
