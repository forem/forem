# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:rspec)
task default: :rspec

task :irb do
  # $: << File.expand_path('lib', __FILE__)
  require 'i18n/tasks'
  require 'i18n/tasks/commands'
  I18n::Tasks::Commands.new(I18n::Tasks::BaseTask.new).irb
end
