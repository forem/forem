require 'rake'
require 'rspec/core/rake_task'
require 'bundler/gem_tasks'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

desc "Open a Pry session preloaded with this library"
task :console do
  sh "pry -I lib -r solargraph.rb"
end

desc "Run the type checker"
task :typecheck do
  sh "bundle exec solargraph typecheck --level typed"
end

desc "Run all tests"
task :test do
  Rake::Task["typecheck"].invoke
  Rake::Task["spec"].invoke
end
