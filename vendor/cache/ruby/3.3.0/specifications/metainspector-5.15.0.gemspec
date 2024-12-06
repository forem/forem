# -*- encoding: utf-8 -*-
# stub: metainspector 5.15.0 ruby lib

Gem::Specification.new do |s|
  s.name = "metainspector".freeze
  s.version = "5.15.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jaime Iniesta".freeze]
  s.date = "2023-05-16"
  s.description = "MetaInspector lets you scrape a web page and get its links, images, texts, meta tags...".freeze
  s.email = "jaimeiniesta@gmail.com".freeze
  s.homepage = "https://github.com/jaimeiniesta/metainspector".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "MetaInspector is a ruby gem for web scraping purposes, that returns metadata from a given URL".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<nokogiri>.freeze, ["~> 1.13".freeze])
  s.add_runtime_dependency(%q<faraday>.freeze, ["~> 2.5".freeze])
  s.add_runtime_dependency(%q<faraday-cookie_jar>.freeze, ["~> 0.0".freeze])
  s.add_runtime_dependency(%q<faraday-encoding>.freeze, ["~> 0.0".freeze])
  s.add_runtime_dependency(%q<faraday-follow_redirects>.freeze, ["~> 0.3".freeze])
  s.add_runtime_dependency(%q<faraday-gzip>.freeze, [">= 0.1".freeze, "< 2.0".freeze])
  s.add_runtime_dependency(%q<faraday-http-cache>.freeze, ["~> 2.5".freeze])
  s.add_runtime_dependency(%q<faraday-retry>.freeze, ["~> 2.0".freeze])
  s.add_runtime_dependency(%q<addressable>.freeze, ["~> 2.8.4".freeze])
  s.add_runtime_dependency(%q<fastimage>.freeze, ["~> 2.2".freeze])
  s.add_runtime_dependency(%q<nesty>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.11".freeze])
  s.add_development_dependency(%q<webmock>.freeze, ["~> 3.17".freeze])
  s.add_development_dependency(%q<awesome_print>.freeze, ["~> 1.9".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
  s.add_development_dependency(%q<pry>.freeze, ["~> 0.14".freeze])
  s.add_development_dependency(%q<puma>.freeze, ["~> 6.2.2".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.34".freeze])
  s.add_development_dependency(%q<resolv>.freeze, ["~> 0.2.2".freeze])
  s.add_development_dependency(%q<sinatra>.freeze, ["~> 3.0.6".freeze])
end
