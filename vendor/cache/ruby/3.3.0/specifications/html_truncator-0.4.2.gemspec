# -*- encoding: utf-8 -*-
# stub: html_truncator 0.4.2 ruby lib

Gem::Specification.new do |s|
  s.name = "html_truncator".freeze
  s.version = "0.4.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Bruno Michel".freeze]
  s.date = "2017-11-30"
  s.description = "Wants to truncate an HTML string properly? This gem is for you.".freeze
  s.email = "bmichel@menfin.info".freeze
  s.extra_rdoc_files = ["README.md".freeze]
  s.files = ["README.md".freeze]
  s.homepage = "http://github.com/nono/HTML-Truncator".freeze
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Wants to truncate an HTML string properly? This gem is for you.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<nokogiri>.freeze, ["~> 1.5".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0".freeze])
end
