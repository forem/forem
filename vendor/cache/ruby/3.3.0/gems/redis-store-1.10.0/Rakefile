require 'bundler/setup'
require 'rake'
require 'bundler/gem_tasks'
require 'appraisal'
require 'rubocop/rake_task'

RuboCop::RakeTask.new :lint

if !ENV["APPRAISAL_INITIALIZED"] && !ENV["CI"]
  task :default do
    sh "appraisal install && rake appraisal default"
  end
else
  require 'redis-store/testing/tasks'
end
