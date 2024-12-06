# frozen_string_literal: true

require File.expand_path("lib/feedjira/version", __dir__)

Gem::Specification.new do |s|
  s.authors = [
    "Adam Hess",
    "Akinori Musha",
    "Ezekiel Templin",
    "Jon Allured",
    "Julien Kirch",
    "Michael Stock",
    "Paul Dix"
  ]
  s.homepage = "https://github.com/feedjira/feedjira"
  s.license  = "MIT"
  s.name     = "feedjira"
  s.platform = Gem::Platform::RUBY
  s.summary  = "A feed parsing library"
  s.version  = Feedjira::VERSION

  s.metadata = {
    "homepage_uri" => "https://github.com/feedjira/feedjira",
    "source_code_uri" => "https://github.com/feedjira/feedjira",
    "changelog_uri" => "https://github.com/feedjira/feedjira/blob/main/CHANGELOG.md",
    "rubygems_mfa_required" => "true"
  }

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ["lib"]

  s.required_ruby_version = ">=2.7"

  s.add_runtime_dependency "loofah", ">= 2.3.1", "< 3"
  s.add_runtime_dependency "sax-machine", ">= 1.0", "< 2"
end
