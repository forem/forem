# -*- encoding: utf-8 -*-
# stub: terser 1.2.2 ruby lib

Gem::Specification.new do |s|
  s.name = "terser".freeze
  s.version = "1.2.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "http://github.com/ahorek/terser-ruby/blob/master/CHANGELOG.md" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Pavel Rosicky".freeze]
  s.date = "2024-04-02"
  s.description = "Terser minifies JavaScript files by wrapping     TerserJS to be accessible in Ruby".freeze
  s.email = ["pdahorek@seznam.cz".freeze]
  s.extra_rdoc_files = ["LICENSE.txt".freeze, "README.md".freeze, "CHANGELOG.md".freeze, "CONTRIBUTING.md".freeze]
  s.files = ["CHANGELOG.md".freeze, "CONTRIBUTING.md".freeze, "LICENSE.txt".freeze, "README.md".freeze]
  s.homepage = "http://github.com/ahorek/terser-ruby".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Ruby wrapper for Terser JavaScript compressor".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<execjs>.freeze, [">= 0.3.0".freeze, "< 3".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.3".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<sourcemap>.freeze, ["~> 0.1.1".freeze])
end
