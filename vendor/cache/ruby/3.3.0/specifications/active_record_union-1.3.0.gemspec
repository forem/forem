# -*- encoding: utf-8 -*-
# stub: active_record_union 1.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "active_record_union".freeze
  s.version = "1.3.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Brian Hempel".freeze]
  s.date = "2018-01-14"
  s.description = "UNIONs in ActiveRecord! Adds proper union and union_all methods to ActiveRecord::Relation.".freeze
  s.email = ["plasticchicken@gmail.com".freeze]
  s.homepage = "https://github.com/brianhempel/active_record_union".freeze
  s.licenses = ["Public Domain".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "UNIONs in ActiveRecord! Adds proper union and union_all methods to ActiveRecord::Relation.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 4.0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.6".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<pry>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<pg>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<mysql2>.freeze, [">= 0".freeze])
end
