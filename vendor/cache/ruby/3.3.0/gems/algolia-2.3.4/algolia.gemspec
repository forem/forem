require 'date'

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'algolia/version'

Gem::Specification.new do |spec|
  spec.name          = 'algolia'
  spec.version       = Algolia::VERSION
  spec.authors       = ['Algolia']
  spec.email         = ['support@algolia.com']

  spec.date        = Date.today
  spec.licenses    = ['MIT']
  spec.summary     = 'A simple Ruby client for the algolia.com REST API'
  spec.description = 'A simple Ruby client for the algolia.com REST API'
  spec.homepage    = 'https://github.com/algolia/algoliasearch-client-ruby'

  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/algolia/algoliasearch-client-ruby/issues',
    'documentation_uri' => 'https://www.algolia.com/doc/api-client/getting-started/install/ruby',
    'source_code_uri' => 'https://github.com/algolia/algoliasearch-client-ruby'
  }

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem
  # that have been added into git.
  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop', '<= 0.82.0'

  spec.add_dependency 'faraday', ['>= 0.15', '< 3']
  spec.add_dependency 'faraday-net_http_persistent', ['>= 0.15', '< 3']

  spec.add_dependency 'multi_json', '~> 1.0'
  spec.add_dependency 'net-http-persistent'

  spec.add_development_dependency 'httpclient'
  spec.add_development_dependency 'm'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'minitest-hooks'
  spec.add_development_dependency 'minitest-proveit'
  spec.add_development_dependency 'webmock'
end
