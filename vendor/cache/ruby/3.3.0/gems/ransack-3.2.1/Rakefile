require 'bundler'
require 'rspec/core/rake_task'

Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new(:spec) do |rspec|
  ENV['SPEC'] = 'spec/ransack/**/*_spec.rb'
  # With Rails 3, using `--backtrace` raises 'invalid option' when testing.
  # With Rails 4 and 5 it can be uncommented to see the backtrace:
  #
  # rspec.rspec_opts = ['--backtrace']
end

task :default do
  Rake::Task["spec"].invoke
end

desc "Open an irb session with Ransack and the sample data used in specs"
task :console do
  require 'pry'
  require File.expand_path('../spec/console.rb', __FILE__)
  ARGV.clear
  Pry.start
end
