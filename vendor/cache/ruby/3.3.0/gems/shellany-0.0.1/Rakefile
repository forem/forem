require "bundler/gem_tasks"

require 'nenv'

default_tasks = []

require 'rspec/core/rake_task'
default_tasks  << RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = Nenv.ci?
end

task default: default_tasks.map(&:name)

