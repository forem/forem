# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'terser/version'

Gem::Specification.new do |spec|
  spec.name = "terser"
  spec.version = Terser::VERSION
  spec.authors = ["Pavel Rosicky"]
  spec.email = ["pdahorek@seznam.cz"]
  spec.homepage = "http://github.com/ahorek/terser-ruby"
  spec.summary = "Ruby wrapper for Terser JavaScript compressor"
  spec.description = "Terser minifies JavaScript files by wrapping \
    TerserJS to be accessible in Ruby"
  spec.license = "MIT"

  spec.required_ruby_version = '>= 2.3.0'

  spec.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md",
    "CHANGELOG.md",
    "CONTRIBUTING.md"
  ]

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(spec|vendor|gemfiles|patches|benchmark|.github)/})
  end
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "execjs", [">= 0.3.0", "< 3"]
  spec.add_development_dependency "bundler", ">= 1.3"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "sourcemap", "~> 0.1.1"

  spec.metadata["changelog_uri"] = spec.homepage + "/blob/master/CHANGELOG.md"
end
