$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'bundler'
Bundler.setup

require 'rake'
require 'rspec'
require 'rspec/core/rake_task'

require 'bullet/version'

task :build do
  system 'gem build bullet.gemspec'
end

task install: :build do
  system "sudo gem install bullet-#{Bullet::VERSION}.gem"
end

task release: :build do
  puts "Tagging #{Bullet::VERSION}..."
  system "git tag -a #{Bullet::VERSION} -m 'Tagging #{Bullet::VERSION}'"
  puts 'Pushing to Github...'
  system 'git push --tags'
  puts 'Pushing to rubygems.org...'
  system "gem push bullet-#{Bullet::VERSION}.gem"
end

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

RSpec::Core::RakeTask.new('spec:progress') do |spec|
  spec.rspec_opts = %w[--format progress]
  spec.pattern = 'spec/**/*_spec.rb'
end

begin
  require 'rdoc/task'

  desc 'Generate documentation for the plugin.'
  Rake::RDocTask.new do |rdoc|
    rdoc.rdoc_dir = 'rdoc'
    rdoc.title = "bullet #{Bullet::VERSION}"
    rdoc.rdoc_files.include('README*')
    rdoc.rdoc_files.include('lib/**/*.rb')
  end
rescue LoadError
  puts 'RDocTask is not supported for this platform'
end

task default: :spec
