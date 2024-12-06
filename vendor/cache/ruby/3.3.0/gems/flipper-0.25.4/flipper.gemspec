# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flipper/version', __FILE__)
require File.expand_path('../lib/flipper/metadata', __FILE__)

plugin_files = []
plugin_test_files = []

Dir['flipper-*.gemspec'].map do |gemspec|
  spec = eval(File.read(gemspec))
  plugin_files << spec.files
  plugin_test_files << spec.files
end

ignored_files = plugin_files
ignored_files << Dir['script/*']
ignored_files << '.travis.yml'
ignored_files << '.gitignore'
ignored_files << 'Guardfile'
ignored_files.flatten!.uniq!

ignored_test_files = plugin_test_files
ignored_test_files.flatten!.uniq!

Gem::Specification.new do |gem|
  gem.authors       = ['John Nunemaker']
  gem.email         = ['nunemaker@gmail.com']
  gem.summary       = 'Feature flipper for ANYTHING'
  gem.homepage      = 'https://github.com/jnunemaker/flipper'
  gem.license       = 'MIT'

  gem.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n") - ignored_files + ['lib/flipper/version.rb']
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n") - ignored_test_files
  gem.name          = 'flipper'
  gem.require_paths = ['lib']
  gem.version       = Flipper::VERSION
  gem.metadata      = Flipper::METADATA
end
