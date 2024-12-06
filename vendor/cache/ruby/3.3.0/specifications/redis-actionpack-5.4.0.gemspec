# -*- encoding: utf-8 -*-
# stub: redis-actionpack 5.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "redis-actionpack".freeze
  s.version = "5.4.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "source_code_uri" => "https://github.com/redis-store/redis-actionpack" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Luca Guidi".freeze]
  s.date = "2023-12-04"
  s.description = "Redis session store for ActionPack. Used for storing the Rails session in Redis.".freeze
  s.email = ["me@lucaguidi.com".freeze]
  s.homepage = "http://redis-store.org/redis-actionpack".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Redis session store for ActionPack".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<redis-store>.freeze, [">= 1.1.0".freeze, "< 2".freeze])
  s.add_runtime_dependency(%q<redis-rack>.freeze, [">= 2.1.0".freeze, "< 4".freeze])
  s.add_runtime_dependency(%q<actionpack>.freeze, [">= 5".freeze, "< 8".freeze])
end
