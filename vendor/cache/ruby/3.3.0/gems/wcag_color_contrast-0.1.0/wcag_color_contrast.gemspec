# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wcag_color_contrast/version'

Gem::Specification.new do |spec|
  spec.name          = 'wcag_color_contrast'
  spec.version       = WCAGColorContrast::VERSION
  spec.authors       = ['Mark Dodwell']
  spec.email         = ['mark@mkdynamic.co.uk']
  spec.summary       = 'Calculate the contrast ratio between 2 colors, for checking against the WCAG recommended contrast ratio for legibility.'
  spec.homepage      = 'https://github.com/mkdynamic/wcag_color_contrast'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split($/)
  spec.executables   = `git ls-files -- bin/*`.split($/).map &File.method(:basename)
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'minitest'
end
