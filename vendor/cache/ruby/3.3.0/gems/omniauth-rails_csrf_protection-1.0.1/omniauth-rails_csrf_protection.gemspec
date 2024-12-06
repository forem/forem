lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "omniauth/rails_csrf_protection/version"

Gem::Specification.new do |spec|
  spec.name        = "omniauth-rails_csrf_protection"
  spec.version     = OmniAuth::RailsCsrfProtection::VERSION
  spec.authors     = ["Cookpad Inc."]
  spec.email       = ["kaihatsu@cookpad.com"]

  spec.summary     = <<~SUMMARY
    Provides CSRF protection on OmniAuth request endpoint on Rails application.
  SUMMARY

  spec.description = <<~DESCRIPTION
    This gem provides a mitigation against CVE-2015-9284 (Cross-Site Request
    Forgery on the request phrase when using OmniAuth gem with a Ruby on Rails
    application) by implementing a CSRF token verifier that directly utilize
    `ActionController::RequestForgeryProtection` code from Rails.
  DESCRIPTION

  spec.homepage    = "https://github.com/cookpad/omniauth-rails_csrf_protection"
  spec.license     = "MIT"

  spec.files       = `git ls-files`.split("\n")
  spec.test_files  = `git ls-files -- test/*`.split("\n")

  spec.require_paths = ["lib"]

  spec.add_dependency "actionpack", ">= 4.2"
  spec.add_dependency "omniauth", "~> 2.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rails"
  spec.add_development_dependency "rake"
end
