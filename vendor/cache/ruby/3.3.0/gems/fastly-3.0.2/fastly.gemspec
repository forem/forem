# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'fastly/gem_version'

Gem::Specification.new do |s|
  s.name        = 'fastly'
  s.version     = Fastly::VERSION
  s.authors     = ['Fastly']
  s.email       = ['simon@fastly.com', 'zeke@templ.in', 'tyler@fastly.com']
  s.homepage    = 'http://github.com/fastly/fastly-ruby'
  s.summary     = %q(Client library for the Fastly acceleration system)
  s.description = %q(Client library for the Fastly acceleration system)
  s.license     = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']
end
