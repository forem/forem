# -*- encoding: utf-8 -*-

require File.expand_path('../lib/stripe_mock/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "stripe-ruby-mock"
  gem.version       = StripeMock::VERSION
  gem.summary       = %q{TDD with stripe}
  gem.description   = %q{A drop-in library to test stripe without hitting their servers}
  gem.license       = "MIT"
  gem.authors       = ["Gilbert"]
  gem.email         = "gilbertbgarza@gmail.com"
  gem.homepage      = "https://github.com/stripe-ruby-mock/stripe-ruby-mock"
  gem.metadata      = {
    "bug_tracker_uri" => "https://github.com/stripe-ruby-mock/stripe-ruby-mock/issues",
    "changelog_uri"   => "https://github.com/stripe-ruby-mock/stripe-ruby-mock/blob/master/CHANGELOG.md",
    "source_code_uri" => "https://github.com/stripe-ruby-mock/stripe-ruby-mock"
  }

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'stripe', '> 5', '< 6'
  gem.add_dependency 'multi_json', '~> 1.0'
  gem.add_dependency 'dante', '>= 0.2.0'

  gem.add_development_dependency 'rspec', '~> 3.7.0'
  gem.add_development_dependency 'rubygems-tasks', '~> 0.2'
  gem.add_development_dependency 'thin', '~> 1.6.4'
end
