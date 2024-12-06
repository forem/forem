# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'naught/version'

Gem::Specification.new do |spec|
  spec.name          = 'naught'
  spec.version       = Naught::VERSION
  spec.authors       = ['Avdi Grimm']
  spec.email         = ['avdi@avdi.org']
  spec.description   = 'Naught is a toolkit for building Null Objects'
  spec.summary       = spec.description
  spec.homepage      = 'https://github.com/avdi/naught'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
end
