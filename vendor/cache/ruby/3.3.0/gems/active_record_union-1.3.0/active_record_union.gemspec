# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_record_union/version'

Gem::Specification.new do |spec|
  spec.name          = "active_record_union"
  spec.version       = ActiveRecordUnion::VERSION
  spec.authors       = ["Brian Hempel"]
  spec.email         = ["plasticchicken@gmail.com"]
  spec.summary       = %q{UNIONs in ActiveRecord! Adds proper union and union_all methods to ActiveRecord::Relation.}
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/brianhempel/active_record_union"
  spec.license       = "Public Domain"

  spec.files         = `git ls-files -z`.split("\x0")
  # spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/}) + spec.files.grep(%r{^bin/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 4.0"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec",   "~> 3.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "mysql2"
end
