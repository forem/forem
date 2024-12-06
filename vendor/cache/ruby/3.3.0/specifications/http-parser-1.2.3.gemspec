# -*- encoding: utf-8 -*-
# stub: http-parser 1.2.3 ruby lib
# stub: ext/Rakefile

Gem::Specification.new do |s|
  s.name = "http-parser".freeze
  s.version = "1.2.3".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Stephen von Takach".freeze]
  s.date = "2021-01-11"
  s.description = "    A super fast http parser for ruby.\n    Cross platform and multiple ruby implementation support thanks to ffi.\n".freeze
  s.email = ["steve@cotag.me".freeze]
  s.extensions = ["ext/Rakefile".freeze]
  s.extra_rdoc_files = ["README.md".freeze]
  s.files = ["README.md".freeze, "ext/Rakefile".freeze]
  s.homepage = "https://github.com/cotag/http-parser".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Ruby bindings to joyent/http-parser".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<ffi-compiler>.freeze, [">= 1.0".freeze, "< 2.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 11.2".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.5".freeze])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9".freeze])
end
