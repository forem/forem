# -*- encoding: utf-8 -*-
# stub: libhoney 2.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "libhoney".freeze
  s.version = "2.2.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["The Honeycomb.io Team".freeze]
  s.bindir = "exe".freeze
  s.date = "2022-04-14"
  s.description = "Ruby gem for sending data to Honeycomb".freeze
  s.email = "support@honeycomb.io".freeze
  s.homepage = "https://github.com/honeycombio/libhoney-rb".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "send data to Honeycomb".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bump>.freeze, ["~> 0.5".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<lockstep>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0".freeze])
  s.add_development_dependency(%q<minitest-reporters>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["= 1.12.1".freeze])
  s.add_development_dependency(%q<sinatra>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<sinatra-contrib>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<spy>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<webmock>.freeze, ["~> 3.4".freeze])
  s.add_development_dependency(%q<yard>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<yardstick>.freeze, ["~> 0.9".freeze])
  s.add_runtime_dependency(%q<addressable>.freeze, ["~> 2.0".freeze])
  s.add_runtime_dependency(%q<excon>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<http>.freeze, [">= 2.0".freeze, "< 6.0".freeze])
end
