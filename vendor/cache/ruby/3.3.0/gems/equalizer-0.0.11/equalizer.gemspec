# encoding: utf-8

require File.expand_path('../lib/equalizer/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = 'equalizer'
  gem.version     = Equalizer::VERSION.dup
  gem.authors     = ['Dan Kubb', 'Markus Schirp']
  gem.email       = %w[dan.kubb@gmail.com mbj@schirp-dso.com]
  gem.description = 'Module to define equality, equivalence and inspection methods'
  gem.summary     = gem.description
  gem.homepage    = 'https://github.com/dkubb/equalizer'
  gem.licenses    = 'MIT'

  gem.require_paths    = %w[lib]
  gem.files            = `git ls-files`.split("\n")
  gem.test_files       = `git ls-files -- spec/{unit,integration}`.split("\n")
  gem.extra_rdoc_files = %w[LICENSE README.md CONTRIBUTING.md]

  gem.required_ruby_version = '>= 1.8.7'

  gem.add_development_dependency('bundler', '~> 1.3', '>= 1.3.5')
end
