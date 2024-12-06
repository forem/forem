# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "i18n/js/version"

Gem::Specification.new do |s|
  s.name        = "i18n-js"
  s.version     = I18n::JS::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Nando Vieira"]
  s.email       = ["fnando.vieira@gmail.com"]
  s.homepage    = "https://rubygems.org/gems/i18n-js"
  s.summary     = "It's a small library to provide the Rails I18n translations on the Javascript."
  s.description = s.summary
  s.license       = "MIT"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "i18n", ">= 0.6.6"

  s.add_development_dependency "appraisal", "~> 2.3"
  s.add_development_dependency "rspec", "~> 3.0"
  s.add_development_dependency "rake", "~> 12.0"
  s.add_development_dependency "gem-release", ">= 0.7"
  s.add_development_dependency "coveralls", ">= 0.7"

  s.required_ruby_version = ">= 2.1.0"
end
