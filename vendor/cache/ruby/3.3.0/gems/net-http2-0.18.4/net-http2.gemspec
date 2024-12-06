# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'net-http2/version'

Gem::Specification.new do |spec|
  spec.name                  = "net-http2"
  spec.version               = NetHttp2::VERSION
  spec.licenses              = ['MIT']
  spec.authors               = ["Roberto Ostinelli"]
  spec.email                 = ["roberto@ostinelli.net"]
  spec.summary               = %q{NetHttp2 is an HTTP2 client for Ruby.}
  spec.homepage              = "http://github.com/ostinelli/net-http2"
  spec.required_ruby_version = '>=2.1.0'


  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "http-2", "~> 0.11"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"
end
