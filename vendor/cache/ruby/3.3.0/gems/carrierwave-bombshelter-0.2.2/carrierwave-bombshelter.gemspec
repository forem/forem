# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'carrierwave/bombshelter/version'

Gem::Specification.new do |spec|
  spec.name          = 'carrierwave-bombshelter'
  spec.version       = CarrierWave::BombShelter::VERSION
  spec.authors       = ['DarthSim']
  spec.email         = ['darthsim@gmail.com']

  spec.summary       = 'Protect your carrierwave from image bombs'
  spec.homepage      = 'https://github.com/DarthSim/carrierwave-bombshelter'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'fog-core'
  spec.add_development_dependency 'fog'
  spec.add_development_dependency 'fog-aws'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'mime-types', '< 3.0'

  spec.add_dependency 'activesupport', '>= 3.2.0'
  spec.add_dependency 'fastimage'
  spec.add_dependency 'carrierwave'
end
