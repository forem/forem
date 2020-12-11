require "bundler"
Bundler.setup
Bundler::GemHelper.install_tasks

require "rake"

require "rspec/core/rake_task"
require "rspec/core/version"

desc "Run all examples"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.ruby_opts = %w[-w]
end

task :default => [:spec]

task :verify_private_key_present do
  private_key = File.expand_path('~/.gem/rspec-gem-private_key.pem')
  unless File.exist?(private_key)
    raise "Your private key is not present. This gem should not be built without it."
  end
end

task :build => :verify_private_key_present

begin
  require 'rubocop/rake_task'
  desc 'Run RuboCop on the lib directory'
  RuboCop::RakeTask.new(:rubocop) do |task|
    task.patterns = ['lib/**/*.rb']
  end
rescue LoadError
  # No rubocop means no rubocop rake task
end
