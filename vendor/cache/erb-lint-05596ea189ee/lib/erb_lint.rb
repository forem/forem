# frozen_string_literal: true

require 'rubocop'

require 'erb_lint/corrector'
require 'erb_lint/file_loader'
require 'erb_lint/linter_config'
require 'erb_lint/linter_registry'
require 'erb_lint/linter'
require 'erb_lint/offense'
require 'erb_lint/processed_source'
require 'erb_lint/runner_config'
require 'erb_lint/runner'
require 'erb_lint/version'
require 'erb_lint/stats'
require 'erb_lint/reporter'

# Load linters
Dir[File.expand_path('erb_lint/linters/**/*.rb', File.dirname(__FILE__))].each do |file|
  require file
end

# Load reporters
Dir[File.expand_path('erb_lint/reporters/**/*.rb', File.dirname(__FILE__))].each do |file|
  require file
end
