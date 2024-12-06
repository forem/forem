# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fog/aws/version'

Gem::Specification.new do |spec|
  spec.name          = "fog-aws"
  spec.version       = Fog::AWS::VERSION
  spec.authors       = ["Josh Lane", "Wesley Beary"]
  spec.email         = ["me@joshualane.com", "geemus@gmail.com"]
  spec.summary       = %q{Module for the 'fog' gem to support Amazon Web Services.}
  spec.description   = %q{This library can be used as a module for `fog` or as standalone provider
                        to use the Amazon Web Services in applications..}
  spec.homepage      = "https://github.com/fog/fog-aws"
  spec.license       = "MIT"

  spec.files         = Dir['lib/**/*.{rb,json}',
                           'CHANGELOG.md', 'CONTRIBUTING.md', 'CONTRIBUTORS.md',
                           'LICENSE.md', 'README.md', 'fog-aws.gemspec',]
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'github_changelog_generator', '~> 1.16'
  spec.add_development_dependency 'rake',    '>= 12.3.3'
  spec.add_development_dependency 'rubyzip', '~> 2.3.0'
  spec.add_development_dependency 'shindo',  '~> 0.3'

  spec.add_dependency 'fog-core',  '~> 2.1'
  spec.add_dependency 'fog-json',  '~> 1.1'
  spec.add_dependency 'fog-xml',   '~> 0.1'
end
