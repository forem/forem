$LOAD_PATH.unshift File.dirname(__FILE__) + '/lib'
require 'solargraph/version'
require 'date'

Gem::Specification.new do |s|
  s.name        = 'solargraph'
  s.version     = Solargraph::VERSION
  s.date        = Date.today.strftime("%Y-%m-%d")
  s.summary     = "A Ruby language server"
  s.description = "IDE tools for code completion, inline documentation, and static analysis"
  s.authors     = ["Fred Snyder"]
  s.email       = 'admin@castwide.com'
  s.files       = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  s.homepage    = 'https://solargraph.org'
  s.license     = 'MIT'
  s.executables = ['solargraph']
  s.metadata["funding_uri"]     = "https://www.patreon.com/castwide"
  s.metadata["bug_tracker_uri"] = "https://github.com/castwide/solargraph/issues"
  s.metadata["changelog_uri"]   = "https://github.com/castwide/solargraph/blob/master/CHANGELOG.md"
  s.metadata["source_code_uri"] = "https://github.com/castwide/solargraph"

  s.required_ruby_version = '>= 2.6'

  s.add_runtime_dependency 'backport', '~> 1.2'
  s.add_runtime_dependency 'benchmark'
  s.add_runtime_dependency 'bundler', '~> 2.0'
  s.add_runtime_dependency 'diff-lcs', '~> 1.4'
  s.add_runtime_dependency 'e2mmap'
  s.add_runtime_dependency 'jaro_winkler', '~> 1.5'
  s.add_runtime_dependency 'kramdown', '~> 2.3'
  s.add_runtime_dependency 'kramdown-parser-gfm', '~> 1.1'
  s.add_runtime_dependency 'parser', '~> 3.0'
  s.add_runtime_dependency 'rbs', '~> 2.0'
  s.add_runtime_dependency 'reverse_markdown', '~> 2.0'
  s.add_runtime_dependency 'rubocop', '~> 1.38'
  s.add_runtime_dependency 'thor', '~> 1.0'
  s.add_runtime_dependency 'tilt', '~> 2.0'
  s.add_runtime_dependency 'yard', '~> 0.9', '>= 0.9.24'

  s.add_development_dependency 'pry'
  s.add_development_dependency 'public_suffix', '~> 3.1'
  s.add_development_dependency 'rspec', '~> 3.5'
  s.add_development_dependency 'simplecov', '~> 0.14'
  s.add_development_dependency 'webmock', '~> 3.6'
end
