# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "faraday-encoding"
  spec.version       = "0.0.5"
  spec.authors       = ["Takayuki Matsubara"]
  spec.email         = ["takayuki.1229@gmail.com"]
  spec.summary       = %q{A Faraday Middleware sets body encoding when specified by server.}
  spec.description   = %q{A Faraday Middleware sets body encoding when specified by server.}
  spec.homepage      = "https://github.com/ma2gedev/faraday-encoding"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency 'faraday_middleware', '~> 0.10'

  spec.add_runtime_dependency "faraday"
end
