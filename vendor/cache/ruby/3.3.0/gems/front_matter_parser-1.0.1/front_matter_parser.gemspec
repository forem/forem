# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'front_matter_parser/version'

Gem::Specification.new do |spec|
  spec.name          = "front_matter_parser"
  spec.version       = FrontMatterParser::VERSION
  spec.authors       = ["marc"]
  spec.email         = ["marc@lamarciana.com"]
  spec.description   = %q{Parse a front matter from syntactically correct strings or files}
  spec.summary       = %q{Library to parse a front matter from strings or files. It allows writing syntactically correct source files, marking front matters as comments in the source file language.}
  spec.homepage      = "https://github.com/waiting-for-dev/front_matter_parser"
  spec.license       = "LGPL3"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.8"
  spec.add_development_dependency "pry-byebug", "~> 3.7"
  # Test reporting
  spec.add_development_dependency 'rubocop', '~> 1.9'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.2'
  spec.add_development_dependency 'simplecov', '0.17'
  spec.add_development_dependency 'codeclimate-test-reporter', '~> 1.0'
end
