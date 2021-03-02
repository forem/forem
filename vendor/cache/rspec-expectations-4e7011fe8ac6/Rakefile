require 'bundler'
Bundler.setup
Bundler::GemHelper.install_tasks

require 'rake'
require 'rspec/core/rake_task'
require 'rspec/expectations/version'

require 'cucumber/rake/task'
Cucumber::Rake::Task.new(:cucumber)

if RUBY_VERSION >= '2.4' && RUBY_ENGINE == 'ruby'
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new(:rubocop)
end

desc "Run all examples"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.ruby_opts = %w[-w]
end

with_changelog_in_features = lambda do |&block|
  begin
    sh "cp Changelog.md features/"
    block.call
  ensure
    sh "rm features/Changelog.md"
  end
end

desc "Push docs/cukes to relishapp using the relish-client-gem"
task :relish, :version do |_task, args|
  raise "rake relish[VERSION]" unless args[:version]

  with_changelog_in_features.call do
    if `relish versions rspec/rspec-expectations`.split.map(&:strip).include? args[:version]
      puts "Version #{args[:version]} already exists"
    else
      sh "relish versions:add rspec/rspec-expectations:#{args[:version]}"
    end
    sh "relish push rspec/rspec-expectations:#{args[:version]}"
  end
end

desc "Push to relish staging environment"
task :relish_staging do
  with_changelog_in_features.call do
    sh "relish push rspec-staging/rspec-expectations"
  end
end

namespace :clobber do
  desc "delete generated .rbc files"
  task :rbc do
    sh 'find . -name "*.rbc" | xargs rm'
  end
end

desc "delete generated files"
task :clobber => ["clobber:rbc"] do
  rm_rf 'doc'
  rm_rf '.yardoc'
  rm_rf 'pkg'
  rm_rf 'tmp'
  rm_rf 'coverage'
end

if RUBY_VERSION >= '2.4' && RUBY_ENGINE == 'ruby'
  task :default => [:spec, :cucumber, :rubocop]
else
  task :default => [:spec, :cucumber]
end

task :verify_private_key_present do
  private_key = File.expand_path('~/.gem/rspec-gem-private_key.pem')
  unless File.exist?(private_key)
    raise "Your private key is not present. This gem should not be built without it."
  end
end

task :build => :verify_private_key_present
