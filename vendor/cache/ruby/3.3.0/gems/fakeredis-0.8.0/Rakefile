require 'bundler'
Bundler::GemHelper.install_tasks

$:.push File.expand_path("../lib", __FILE__)
require "fakeredis/version"

Bundler::GemHelper.install_tasks

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
  spec.ruby_opts="-w"
end

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = FakeRedis::VERSION

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "fakeredis #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

