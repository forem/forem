# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'knapsack_pro/version'

Gem::Specification.new do |spec|
  spec.name          = "knapsack_pro"
  spec.version       = KnapsackPro::VERSION
  spec.authors       = ['ArturT']
  spec.email         = ['arturtrzop@gmail.com']
  spec.summary       = %q{Knapsack Pro splits tests across parallel CI nodes and ensures each parallel job finish work at a similar time.}
  spec.description   = %q{Run tests in parallel across CI server nodes based on tests execution time. Split tests in a dynamic way to ensure parallel jobs are done at a similar time. Thanks to that your CI build time is as fast as possible. It works with many CI providers.}
  spec.homepage      = 'https://knapsackpro.com'
  spec.license       = 'MIT'
  spec.metadata    = {
    'bug_tracker_uri' => 'https://github.com/KnapsackPro/knapsack_pro-ruby/issues',
    'changelog_uri' => 'https://github.com/KnapsackPro/knapsack_pro-ruby/blob/master/CHANGELOG.md',
    'documentation_uri' => 'https://docs.knapsackpro.com/integration/',
    'homepage_uri' => 'https://knapsackpro.com',
    'source_code_uri' => 'https://github.com/KnapsackPro/knapsack_pro-ruby'
  }

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'rake', '>= 0'

  spec.add_development_dependency 'bundler', '>= 1.6'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-its', '~> 1.3'
  spec.add_development_dependency 'cucumber', '>= 0'
  spec.add_development_dependency 'spinach', '>= 0.8'
  spec.add_development_dependency 'minitest', '>= 5.0.0'
  spec.add_development_dependency 'test-unit', '>= 3.0.0'
  spec.add_development_dependency 'pry', '~> 0'
  spec.add_development_dependency 'vcr', '>= 6.0'
  spec.add_development_dependency 'webmock', '>= 3.13'
  spec.add_development_dependency 'timecop', '>= 0.9.4'
end
