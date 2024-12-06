require 'bundler/gem_tasks'

desc 'Run library from within a Pry console'
task :console do
  require 'pry'
  require 'fastly'
  ARGV.clear
  Pry.start
end

namespace :clean do
  desc 'Remove all trailing whitespace from Ruby files in lib and test'
  task :whitespace do
    sh "find {test,lib,bin} -name *.rb -exec sed -i '' 's/[ ]*$//' {} \\\;"
  end
end

require 'rubocop/rake_task'

desc 'Run rubocop'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = ['bin/*', 'lib/**/*.rb', 'test/**/*.rb']
  task.formatters = ['fuubar']
  task.fail_on_error = true
end

require 'rdoc/task'

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.main = 'README.md'
  rdoc.rdoc_files.include('README.md', 'lib/**/*.rb')
end

require 'rake/testtask'

namespace :test do
  desc 'Run all unit tests'
  Rake::TestTask.new(:unit) do |t|
    t.libs << 'test'
    t.test_files = FileList['test/fastly/*_test.rb']
    t.verbose = true
  end
end

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/*test.rb']
  t.verbose = true
end

task default: :test
