# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

require 'bundler'
Bundler::GemHelper.install_tasks

task :default do
  if ENV['BUNDLE_GEMFILE'] =~ /gemfiles/
    Rake::Task['spec'].invoke
  else
    Rake::Task['appraise'].invoke
  end
end

task :appraise do
  exec 'appraisal install && appraisal rake'
end

desc 'Run all amazing_print gem specs'
task :spec do
  # Run plain rspec command without RSpec::Core::RakeTask overrides.
  exec 'rspec -c spec'
end
