# -*- encoding: utf-8 -*-
# stub: omniauth-twitter 1.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "omniauth-twitter".freeze
  s.version = "1.4.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Arun Agrawal".freeze]
  s.date = "2017-02-07"
  s.description = "OmniAuth strategy for Twitter".freeze
  s.email = ["arunagw@gmail.com".freeze]
  s.homepage = "https://github.com/arunagw/omniauth-twitter".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "OmniAuth strategy for Twitter".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<omniauth-oauth>.freeze, ["~> 1.1".freeze])
  s.add_runtime_dependency(%q<rack>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.0".freeze])
end
