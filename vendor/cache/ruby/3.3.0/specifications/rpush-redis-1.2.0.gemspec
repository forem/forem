# -*- encoding: utf-8 -*-
# stub: rpush-redis 1.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rpush-redis".freeze
  s.version = "1.2.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ian Leitch".freeze]
  s.date = "2021-04-29"
  s.description = "Redis dependencies for Rpush.".freeze
  s.email = ["port001@gmail.com".freeze]
  s.homepage = "".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Redis dependencies for Rpush.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<modis>.freeze, [">= 3.0".freeze, "< 5.0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
end
