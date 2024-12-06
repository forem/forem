require "appraisal"
require "rubygems"
require "bundler"
require "rspec/core/rake_task"

Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new(:"spec:ruby")

desc "Run JavaScript specs"
task "spec:js" do
  # Need to call `exit!` manually to propogate exit status
  system "npm", "test" or exit!(1)
end

desc "Run all specs"
task :spec => ["spec:ruby", "spec:js"]

if !ENV["APPRAISAL_INITIALIZED"] && !ENV["TRAVIS"]
  task :default do
    sh "appraisal install && rake appraisal spec"
  end
else
  task :default => :spec
end
