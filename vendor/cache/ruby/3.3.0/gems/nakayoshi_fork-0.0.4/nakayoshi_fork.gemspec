# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nakayoshi_fork/version'

Gem::Specification.new do |spec|
  spec.name          = "nakayoshi_fork"
  spec.version       = NakayoshiFork::VERSION
  spec.authors       = ["Koichi Sasada"]
  spec.email         = ["ko1@atdot.net"]
  spec.summary       = %q{nakayoshi_fork gem solves CoW friendly problem on MRI 2.2 and later.}
  spec.description   = %q{nakayoshi_fork gem solves CoW friendly problem on MRI 2.2 and later.}
  spec.homepage      = "https://github.com/ko1/nakayoshi_fork"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
