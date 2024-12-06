# encoding: UTF-8

require 'bundler/gem_tasks'

require 'rake'
require 'rake/testtask'

task :default => [:test]

test_task = Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end
