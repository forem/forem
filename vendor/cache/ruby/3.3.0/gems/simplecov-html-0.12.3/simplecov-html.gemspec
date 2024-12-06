# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require "simplecov-html/version"

Gem::Specification.new do |gem|
  gem.name        = "simplecov-html"
  gem.version     = SimpleCov::Formatter::HTMLFormatter::VERSION
  gem.platform    = Gem::Platform::RUBY
  gem.authors     = ["Christoph Olszowka"]
  gem.email       = ["christoph at olszowka de"]
  gem.homepage    = "https://github.com/simplecov-ruby/simplecov-html"
  gem.description = %(Default HTML formatter for SimpleCov code coverage tool for ruby 2.4+)
  gem.summary     = gem.description
  gem.license     = "MIT"

  gem.required_ruby_version = ">= 2.4"

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  gem.require_paths = ["lib"]
end
