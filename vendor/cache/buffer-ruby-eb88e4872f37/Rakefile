require "bundler/gem_tasks"
require 'rake'
require 'rspec/core/rake_task'

desc 'Default: run specs.'
task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  # Put spec opts in a file named .rspec in root
end

desc "Generate code coverage"
RSpec::Core::RakeTask.new(:coverage) do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  t.rcov = true
  t.rcov_opts = %w[--exclude spec]
end

task :default  => :spec

task :curl_dump, [ :url ] do |t, args|
  access_token = `cat ~/.bufferapprc | head -3 | tail -1`.chomp
  sh "curl -is #{args[:url]}?access_token=#{access_token}"
end
