lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'counter_culture/version'

Gem::Specification.new do |spec|
  spec.name          = 'counter_culture'
  spec.version       = CounterCulture::VERSION
  spec.authors       = ['Magnus von Koeller']
  spec.email         = ["magnus@vonkoeller.de"]

  spec.summary       = 'Turbo-charged counter caches for your Rails app.'
  spec.description   = 'counter_culture provides turbo-charged counter caches that are kept up-to-date not just on create and destroy, that support multiple levels of indirection through relationships, allow dynamic column names and that avoid deadlocks by updating in the after_commit callback.'
  spec.homepage      = 'https://github.com/magnusvk/counter_culture'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 2.6'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.extra_rdoc_files = ['LICENSE.txt', 'README.md']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '>= 4.2'
  spec.add_dependency 'activesupport', '>= 4.2'

  spec.add_development_dependency 'appraisal', '> 2.0.0'
  spec.add_development_dependency 'awesome_print'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'database_cleaner', '>= 1.1.1'
  spec.add_development_dependency 'discard'
  spec.add_development_dependency 'paper_trail'
  spec.add_development_dependency 'paranoia'
  spec.add_development_dependency 'after_commit_action'
  spec.add_development_dependency 'rails', '>= 4.2'
  spec.add_development_dependency 'rake', '>= 10.0'
  spec.add_development_dependency 'rdoc', ">= 6.3.1"
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-extra-formatters'
  spec.add_development_dependency 'simplecov', '~> 0.16.1'
  spec.add_development_dependency 'timecop'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'mysql2'
  spec.add_development_dependency 'pg'
end
