# -*- encoding: utf-8 -*-
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'derailed_benchmarks/version'

Gem::Specification.new do |gem|
  gem.name          = "derailed_benchmarks"
  gem.version       = DerailedBenchmarks::VERSION
  gem.authors       = ["Richard Schneeman"]
  gem.email         = ["richard.schneeman+rubygems@gmail.com"]
  gem.description   = %q{ Go faster, off the Rails }
  gem.summary       = %q{ Benchmarks designed to performance test your ENTIRE site }
  gem.homepage      = "https://github.com/zombocom/derailed_benchmarks"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = ">= 2.5.0"

  gem.add_dependency "heapy",           "~> 0"
  gem.add_dependency "memory_profiler", ">= 0", "< 2"
  gem.add_dependency "get_process_mem", "~> 0"
  gem.add_dependency "benchmark-ips",   "~> 2"
  gem.add_dependency "rack",            ">= 1"
  gem.add_dependency "rake",            "> 10", "< 14"
  gem.add_dependency "thor",            ">= 0.19", "< 2"
  gem.add_dependency "ruby-statistics", ">= 2.1"
  gem.add_dependency "mini_histogram",  ">= 0.3.0"
  gem.add_dependency "dead_end",        ">= 0"
  gem.add_dependency "rack-test",       ">= 0"

  gem.add_development_dependency "webrick",  ">= 0"
  gem.add_development_dependency "capybara",  "~> 2"
  gem.add_development_dependency "m"
  gem.add_development_dependency "rails",     "> 3", "<= 7"
  gem.add_development_dependency "devise",    "> 3", "< 6"
end
