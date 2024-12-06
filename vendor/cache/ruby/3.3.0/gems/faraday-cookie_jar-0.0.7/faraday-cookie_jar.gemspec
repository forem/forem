# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'faraday/cookie_jar/version'

Gem::Specification.new do |spec|
  spec.name          = "faraday-cookie_jar"
  spec.version       = Faraday::CookieJarVersion::VERSION
  spec.authors       = ["Tatsuhiko Miyagawa"]
  spec.email         = ["miyagawa@bulknews.net"]
  spec.description   = %q{Cookie jar middleware for Faraday}
  spec.summary       = %q{Manages client-side cookie jar for Faraday HTTP client}
  spec.homepage      = "https://github.com/miyagawa/faraday-cookie_jar"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", ">= 0.8.0"
  spec.add_dependency "http-cookie", "~> 1.0.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.2"
  spec.add_development_dependency "sinatra"
  spec.add_development_dependency "sham_rack"
end
