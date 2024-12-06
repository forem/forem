# -*- encoding: utf-8 -*-
# stub: mini_histogram 0.3.1 ruby lib

Gem::Specification.new do |s|
  s.name = "mini_histogram".freeze
  s.version = "0.3.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "homepage_uri" => "https://github.com/zombocom/mini_histogram" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["schneems".freeze]
  s.bindir = "exe".freeze
  s.date = "2020-09-24"
  s.description = "It makes histograms out of Ruby data. How cool is that!? Pretty cool if you ask me.".freeze
  s.email = ["richard.schneeman+foo@gmail.com".freeze]
  s.homepage = "https://github.com/zombocom/mini_histogram".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.1.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "A small gem for building histograms out of Ruby arrays".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<m>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<benchmark-ips>.freeze, [">= 0".freeze])
end
