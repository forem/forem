# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "fakeredis/version"

Gem::Specification.new do |s|
  s.name        = "fakeredis"
  s.version     = FakeRedis::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Guillermo Iguaran"]
  s.email       = ["guilleiguaran@gmail.com"]
  s.homepage    = "https://guilleiguaran.github.com/fakeredis"
  s.license     = "MIT"
  s.summary     = %q{Fake (In-memory) driver for redis-rb.}
  s.description = %q{Fake (In-memory) driver for redis-rb. Useful for testing environment and machines without Redis.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency(%q<redis>, ["~> 4.1"])
  s.add_development_dependency(%q<rspec>, ["~> 3.0"])
end
