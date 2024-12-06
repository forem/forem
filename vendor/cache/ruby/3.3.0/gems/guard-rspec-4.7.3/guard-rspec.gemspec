# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "guard/rspec/version"

Gem::Specification.new do |s|
  s.name        = "guard-rspec"
  s.version     = Guard::RSpecVersion::VERSION
  s.author      = "Thibaud Guillaume-Gentil"
  s.email       = "thibaud@thibaud.gg"
  s.summary     = "Guard gem for RSpec"
  s.description = "Guard::RSpec automatically run your specs" \
                  " (much like autotest)."

  s.homepage    = "https://github.com/guard/guard-rspec"
  s.license     = "MIT"

  s.files        = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  s.test_files   = s.files.grep(%r{^spec/})
  s.require_path = "lib"

  s.add_dependency "guard", "~> 2.1"
  s.add_dependency "guard-compat", "~> 1.1"
  s.add_dependency "rspec", ">= 2.99.0", "< 4.0"
end
