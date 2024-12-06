# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'octokit/version'

Gem::Specification.new do |spec|
  spec.add_development_dependency 'bundler', '>= 1', '< 3'
  spec.add_dependency 'faraday', '>= 1', '< 3'
  spec.add_dependency 'sawyer', '~> 0.9'
  spec.authors = ['Wynn Netherland', 'Erik Michaels-Ober', 'Clint Shryock']
  spec.description = 'Simple wrapper for the GitHub API'
  spec.email = ['wynn.netherland@gmail.com', 'sferik@gmail.com', 'clint@ctshryock.com']
  spec.files = %w[.document CONTRIBUTING.md LICENSE.md README.md Rakefile octokit.gemspec]
  spec.files += Dir.glob('lib/**/*.rb')
  spec.homepage = 'https://github.com/octokit/octokit.rb'
  spec.licenses = ['MIT']
  spec.name = 'octokit'
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.7.0'
  spec.required_rubygems_version = '>= 1.3.5'
  spec.summary = 'Ruby toolkit for working with the GitHub API'
  spec.version = Octokit::VERSION.dup
  spec.metadata = { 'rubygems_mfa_required' => 'true' }
end
