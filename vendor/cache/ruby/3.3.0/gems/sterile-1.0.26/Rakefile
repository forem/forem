require 'bundler'
require 'rake/testtask'

Bundler::GemHelper.install_tasks

Rake::TestTask.new do |t|
  t.libs << 'test'
end
task default: :test

# Watch rb files, run tests whenever something changes. Requires entr
task :watch do
  sh "find . -name '*.rb' | entr -c rake"
end
