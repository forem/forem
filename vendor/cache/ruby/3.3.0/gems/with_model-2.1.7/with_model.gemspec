# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'with_model/version'

Gem::Specification.new do |spec|
  spec.name        = 'with_model'
  spec.version     = WithModel::VERSION
  spec.authors     = ['Case Commons, LLC', 'Grant Hutchins', 'Andrew Marshall']
  spec.email       = %w[casecommons-dev@googlegroups.com gems@nertzy.com andrew@johnandrewmarshall.com]
  spec.homepage    = 'https://github.com/Casecommons/with_model'
  spec.summary     = 'Dynamically build a model within an RSpec context'
  spec.description = spec.summary
  spec.license     = 'MIT'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.7'

  spec.add_dependency 'activerecord', '>= 6.0'
end
