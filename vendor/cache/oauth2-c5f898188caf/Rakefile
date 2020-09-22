# encoding: utf-8

# !/usr/bin/env rake

require 'bundler/gem_tasks'

begin
  require 'wwtd/tasks'
rescue LoadError
  puts 'failed to load wwtd'
end

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  task :spec do
    warn 'rspec is disabled'
  end
end
task :test => :spec

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new do |task|
    task.options = ['-D'] # Display the name of the failing cops
  end
rescue LoadError
  task :rubocop do
    warn 'RuboCop is disabled'
  end
end

namespace :doc do
  require 'rdoc/task'
  require File.expand_path('../lib/oauth2/version', __FILE__)
  RDoc::Task.new do |rdoc|
    rdoc.rdoc_dir = 'rdoc'
    rdoc.title = "oauth2 #{OAuth2::Version}"
    rdoc.main = 'README.md'
    rdoc.rdoc_files.include('README.md', 'LICENSE.md', 'lib/**/*.rb')
  end
end

task :default => [:test, :rubocop]
