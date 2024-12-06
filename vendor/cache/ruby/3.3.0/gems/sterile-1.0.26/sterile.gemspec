# encoding: UTF-8

$:.push File.expand_path("../lib", __FILE__)
require "sterile/version"

Gem::Specification.new do |s|
  s.name        = "sterile"
  s.version     = Sterile::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Patrick Hogan"]
  s.email       = ["pbhogan@gmail.com"]
  s.homepage    = "https://github.com/pbhogan/sterile"
  s.licenses    = ['MIT']
  s.summary     = %q{Sterilize your strings! Transliterate, generate slugs, smart format, strip tags, encode/decode entities and more.}
  s.description = s.summary

  s.add_dependency("nokogiri", ">= 1.11.7")

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths  = ["lib"]
end
