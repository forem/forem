# encoding: utf-8

require "rake/testtask"
require "bundler/gem_tasks"

task default: [:test]

Rake::TestTask.new do |test|
  test.libs       = %w[lib test]
  test.verbose    = true
  test.warning    = true
  test.test_files = FileList["test/test*.rb"]
end

desc "Run some interactive acceptance tests"
task :acceptance do
  load "test/acceptance/acceptance.rb"
end
