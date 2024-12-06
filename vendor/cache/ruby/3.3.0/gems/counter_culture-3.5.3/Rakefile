require 'rubygems'
require 'bundler'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rdoc/task'
require 'counter_culture/version'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

Rake::RDocTask.new do |rdoc|
  version = CounterCulture::VERSION

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "counter_culture #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task default: :spec
