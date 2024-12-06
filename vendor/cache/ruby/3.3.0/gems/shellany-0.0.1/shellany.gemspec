# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'shellany/version'

Gem::Specification.new do |spec|
  spec.name          = "shellany"
  spec.version       = Shellany::VERSION
  spec.authors       = ["Cezary Baginski"]
  spec.email         = ["cezary@chronomantic.net"]
  spec.summary       = %q{Simple, somewhat portable command capturing}
  spec.description   = %q{MRI+JRuby compatible command output capturing}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
end
