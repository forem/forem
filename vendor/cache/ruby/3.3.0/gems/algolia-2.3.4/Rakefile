require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'
require 'git_precommit'

task(:default) { system 'rake --tasks' }
task test: 'test:unit'

RuboCop::RakeTask.new
GitPrecommit::PrecommitTasks.new

task :precommit do
  Rake::Task['rubocop'].invoke
end

namespace :test do
  Rake::TestTask.new(:unit) do |t|
    t.libs << 'test'
    t.libs << 'lib'
    t.test_files = FileList['test/algolia/unit/**/*_test.rb']
    t.verbose    = true
    t.warning    = false
  end

  Rake::TestTask.new(:integration) do |t|
    t.libs << 'test'
    t.libs << 'lib'
    t.test_files = FileList['test/algolia/integration/**/*_test.rb']
    t.verbose    = true
    t.warning    = false
  end

  desc 'Run unit and integration tests'
  task :all do
    Rake::Task['test:unit'].invoke
    Rake::Task['test:integration'].invoke
  end
end

desc 'Run linting, unit and integration tests'
task :all do
  Rake::Task['rubocop'].invoke
  Rake::Task['test:unit'].invoke
  Rake::Task['test:integration'].invoke
end
