# -*- encoding: utf-8 -*-
# stub: sanitize 6.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "sanitize".freeze
  s.version = "6.0.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2.0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ryan Grove".freeze]
  s.date = "2023-07-06"
  s.description = "Sanitize is an allowlist-based HTML and CSS sanitizer. It removes all HTML and/or CSS from a string except the elements, attributes, and properties you choose to allow.".freeze
  s.email = "ryan@wonko.com".freeze
  s.homepage = "https://github.com/rgrove/sanitize/".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Allowlist-based HTML and CSS sanitizer.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<crass>.freeze, ["~> 1.0.2".freeze])
  s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 1.12.0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.14.4".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0.6".freeze])
end
