# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'get_process_mem/version'

Gem::Specification.new do |gem|
  gem.name          = "get_process_mem"
  gem.version       = GetProcessMem::VERSION
  gem.authors       = ["Richard Schneeman"]
  gem.email         = ["richard.schneeman+rubygems@gmail.com"]
  gem.description   = %q{ Get memory usage of a process in Ruby }
  gem.summary       = %q{ Use GetProcessMem to find out the amount of RAM used by any process }
  gem.homepage      = "https://github.com/schneems/get_process_mem"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "ffi", "~> 1.0"

  gem.add_development_dependency "sys-proctable", "~> 1.2"
  gem.add_development_dependency "rake", "~> 12"
  gem.add_development_dependency "test-unit", "~> 3"
end
