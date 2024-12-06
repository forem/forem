# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flipper/version', __FILE__)
require File.expand_path('../lib/flipper/metadata', __FILE__)

flipper_active_record_files = lambda do |file|
  file =~ /active_record/
end

Gem::Specification.new do |gem|
  gem.authors       = ['John Nunemaker']
  gem.email         = ['nunemaker@gmail.com']
  gem.summary       = 'ActiveRecord adapter for Flipper'
  gem.license       = 'MIT'
  gem.homepage      = 'https://github.com/jnunemaker/flipper'

  extra_files = [
    'lib/generators/flipper/templates/migration.erb',
    'lib/flipper/version.rb',
  ]
  gem.files         = `git ls-files`.split("\n").select(&flipper_active_record_files) + extra_files
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n").select(&flipper_active_record_files)
  gem.name          = 'flipper-active_record'
  gem.require_paths = ['lib']
  gem.version       = Flipper::VERSION
  gem.metadata      = Flipper::METADATA

  gem.add_dependency 'flipper', "~> #{Flipper::VERSION}"
  gem.add_dependency 'activerecord', '>= 4.2', '< 8'
end
