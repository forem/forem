# -*- encoding: utf-8 -*-
# stub: rack-host-redirect 1.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rack-host-redirect".freeze
  s.version = "1.3.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Geoff Buesing".freeze]
  s.date = "2017-04-04"
  s.email = "gbuesing@gmail.com".freeze
  s.homepage = "https://github.com/gbuesing/rack-host-redirect".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Lean and simple host redirection via Rack middleware".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rack>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rack-test>.freeze, [">= 0".freeze])
end
