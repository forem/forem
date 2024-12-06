# -*- encoding: utf-8 -*-
# stub: jsonapi-serializer 2.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "jsonapi-serializer".freeze
  s.version = "2.2.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["JSON:API Serializer Community".freeze]
  s.date = "2021-03-11"
  s.description = "Fast, simple and easy to use JSON:API serialization library (also known as fast_jsonapi).".freeze
  s.email = "".freeze
  s.extra_rdoc_files = ["LICENSE.txt".freeze, "README.md".freeze]
  s.files = ["LICENSE.txt".freeze, "README.md".freeze]
  s.homepage = "https://github.com/jsonapi-serializer/jsonapi-serializer".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Fast JSON:API serialization library".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 4.2".freeze])
  s.add_development_dependency(%q<activerecord>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<byebug>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<ffaker>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<jsonapi-rspec>.freeze, [">= 0.0.5".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop-performance>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 0".freeze])
end
