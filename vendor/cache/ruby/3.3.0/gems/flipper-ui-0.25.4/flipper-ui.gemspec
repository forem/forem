# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flipper/version', __FILE__)
require File.expand_path('../lib/flipper/metadata', __FILE__)

flipper_ui_files = lambda do |file|
  file =~ %r{(docs|examples|flipper)[\/-]ui}
end

Gem::Specification.new do |gem|
  gem.authors       = ['John Nunemaker']
  gem.email         = ['nunemaker@gmail.com']
  gem.summary       = 'UI for the Flipper gem'
  gem.license       = 'MIT'
  gem.homepage      = 'https://github.com/jnunemaker/flipper'

  gem.files         = `git ls-files`.split("\n").select(&flipper_ui_files) + ['lib/flipper/version.rb']
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n").select(&flipper_ui_files)
  gem.name          = 'flipper-ui'
  gem.require_paths = ['lib']
  gem.version       = Flipper::VERSION
  gem.metadata      = Flipper::METADATA

  gem.add_dependency 'rack', '>= 1.4', '< 3'
  gem.add_dependency 'rack-protection', '>= 1.5.3', '<= 4.0.0'
  gem.add_dependency 'flipper', "~> #{Flipper::VERSION}"
  gem.add_dependency 'erubi', '>= 1.0.0', '< 2.0.0'
  gem.add_dependency 'sanitize', '< 7'
end
