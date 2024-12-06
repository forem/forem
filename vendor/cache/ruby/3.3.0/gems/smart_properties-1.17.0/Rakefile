#!/usr/bin/env rake
require 'bundler/setup'
require 'bundler/gem_tasks'

begin
  require 'yard'
  YARD::Rake::YardocTask.new do |t|
    t.files   = ['lib/**/*.rb', 'README.md']
  end
rescue LoadError
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec

