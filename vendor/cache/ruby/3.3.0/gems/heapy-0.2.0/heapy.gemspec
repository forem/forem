# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'heapy/version'

Gem::Specification.new do |spec|
  spec.name          = "heapy"
  spec.version       = Heapy::VERSION
  spec.authors       = ["schneems"]
  spec.email         = ["richard.schneeman@gmail.com"]

  spec.summary       = %q{Inspects Ruby heap dumps}
  spec.description   = %q{Got a heap dump? Great. Use this tool to see what's in it!}
  spec.homepage      = "https://github.com/schneems/heapy"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "thor"

  spec.add_development_dependency "bundler", "> 1"
  spec.add_development_dependency "rake", "> 10.0"
  spec.add_development_dependency "rspec"
end
