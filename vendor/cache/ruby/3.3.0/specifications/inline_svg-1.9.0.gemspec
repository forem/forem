# -*- encoding: utf-8 -*-
# stub: inline_svg 1.9.0 ruby lib

Gem::Specification.new do |s|
  s.name = "inline_svg".freeze
  s.version = "1.9.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["James Martin".freeze]
  s.date = "2023-03-29"
  s.description = "Get an SVG into your view and then style it with CSS.".freeze
  s.email = ["inline_svg@jmrtn.com".freeze]
  s.homepage = "https://github.com/jamesmartin/inline_svg".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Embeds an SVG document, inline.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.2".freeze])
  s.add_development_dependency(%q<rspec_junit_formatter>.freeze, ["= 0.2.2".freeze])
  s.add_development_dependency(%q<pry>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 3.0".freeze])
  s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 1.6".freeze])
end
