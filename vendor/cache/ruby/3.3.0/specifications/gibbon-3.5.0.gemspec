# -*- encoding: utf-8 -*-
# stub: gibbon 3.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "gibbon".freeze
  s.version = "3.5.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Amro Mousa".freeze]
  s.date = "2023-06-07"
  s.description = "A wrapper for MailChimp API 3.0".freeze
  s.email = ["amromousa@gmail.com".freeze]
  s.homepage = "http://github.com/amro/gibbon".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "A wrapper for MailChimp API 3.0".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<faraday>.freeze, [">= 1.0".freeze])
  s.add_runtime_dependency(%q<multi_json>.freeze, [">= 1.11.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["= 3.5.0".freeze])
  s.add_development_dependency(%q<webmock>.freeze, ["~> 3.8".freeze])
end
