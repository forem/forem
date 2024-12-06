# -*- encoding: utf-8 -*-
# stub: field_test 0.6.0 ruby lib
# stub: ext/field_test/extconf.rb

Gem::Specification.new do |s|
  s.name = "field_test".freeze
  s.version = "0.6.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andrew Kane".freeze]
  s.date = "2023-07-02"
  s.email = "andrew@ankane.org".freeze
  s.extensions = ["ext/field_test/extconf.rb".freeze]
  s.files = ["ext/field_test/extconf.rb".freeze]
  s.homepage = "https://github.com/ankane/field_test".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "A/B testing for Rails".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<railties>.freeze, [">= 6.1".freeze])
  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 6.1".freeze])
  s.add_runtime_dependency(%q<browser>.freeze, [">= 2".freeze])
  s.add_runtime_dependency(%q<rice>.freeze, [">= 4.0.2".freeze])
end
