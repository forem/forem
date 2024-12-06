# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "thread"
  spec.version       = "0.2.2"
  spec.authors       = ["meh."]
  spec.email         = ["meh@schizofreni.co"]
  spec.summary       = %q{Various extensions to the base thread library.}
  spec.description   = %q{Includes a thread pool, message passing capabilities, a recursive mutex, promise, future and delay.}
  spec.homepage      = "http://github.com/meh/ruby-thread"
  spec.license       = "WTFPL"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rake"
end
