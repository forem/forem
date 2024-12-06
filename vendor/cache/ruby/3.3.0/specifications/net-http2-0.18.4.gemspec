# -*- encoding: utf-8 -*-
# stub: net-http2 0.18.4 ruby lib

Gem::Specification.new do |s|
  s.name = "net-http2".freeze
  s.version = "0.18.4".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Roberto Ostinelli".freeze]
  s.bindir = "exe".freeze
  s.date = "2021-01-07"
  s.email = ["roberto@ostinelli.net".freeze]
  s.homepage = "http://github.com/ostinelli/net-http2".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.1.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "NetHttp2 is an HTTP2 client for Ruby.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<http-2>.freeze, ["~> 0.11".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 12.3.3".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0".freeze])
end
