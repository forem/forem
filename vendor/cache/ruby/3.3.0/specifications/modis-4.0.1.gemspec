# -*- encoding: utf-8 -*-
# stub: modis 4.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "modis".freeze
  s.version = "4.0.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ian Leitch".freeze]
  s.date = "2022-03-02"
  s.description = "ActiveModel + Redis".freeze
  s.email = ["port001@gmail.com".freeze]
  s.homepage = "https://github.com/rpush/modis".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "ActiveModel + Redis".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activemodel>.freeze, [">= 5.2".freeze])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 5.2".freeze])
  s.add_runtime_dependency(%q<redis>.freeze, [">= 3.0".freeze])
  s.add_runtime_dependency(%q<connection_pool>.freeze, [">= 2".freeze])
  s.add_runtime_dependency(%q<msgpack>.freeze, [">= 0.5".freeze])
  s.add_development_dependency(%q<appraisal>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<codeclimate-test-reporter>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<cane>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["= 0.81.0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<hiredis>.freeze, [">= 0.5".freeze])
end
