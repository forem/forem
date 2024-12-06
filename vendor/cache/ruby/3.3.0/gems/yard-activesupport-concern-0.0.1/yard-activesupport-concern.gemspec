# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'yard-activesupport-concern/version'

Gem::Specification.new do |spec|
  spec.name          = 'yard-activesupport-concern'
  spec.version       = YARD::ActiveSupport::Concern::VERSION
  spec.authors       = ['Olivier Lance @ Digital cuisine']
  spec.email         = ['olivier@digitalcuisine.fr']
  spec.summary       = %q{A YARD plugin to handle modules using ActiveSupport::Concern}
  spec.description   = %q{This is a YARD extension that brings support for modules making use of ActiveSupport::Concern. It makes YARD parse docstrings inside included and class_methods blocks and generate the proper documentation for them.}
  spec.homepage      = 'https://github.com/digitalcuisine/yard-activesupport-concern'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'

  spec.add_dependency 'yard', '>= 0.8'

end
