#!/usr/bin/env rake
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'rake/testtask'
require 'flipper/version'

# gem install pkg/*.gem
# gem uninstall flipper flipper-ui flipper-redis
desc 'Build gem into the pkg directory'
task :build do
  FileUtils.rm_rf('pkg')
  Dir['*.gemspec'].each do |gemspec|
    system "gem build #{gemspec}"
  end
  FileUtils.mkdir_p('pkg')
  FileUtils.mv(Dir['*.gem'], 'pkg')
end

desc 'Tags version, pushes to remote, and pushes gem'
task release: :build do
  sh 'git', 'tag', "v#{Flipper::VERSION}"
  sh 'git push origin master'
  sh "git push origin v#{Flipper::VERSION}"
  puts "\nWhat OTP code should be used?"
  otp_code = STDIN.gets.chomp
  sh "ls pkg/*.gem | xargs -n 1 gem push --otp #{otp_code}"
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = %w(--color --format documentation)
end

namespace :spec do
  desc 'Run specs for UI queue'
  RSpec::Core::RakeTask.new(:ui) do |t|
    t.rspec_opts = %w(--color)
    t.pattern = ['spec/flipper/ui/**/*_spec.rb', 'spec/flipper/ui_spec.rb']
  end
end

Rake::TestTask.new do |t|
  t.libs = %w(lib test)
  t.pattern = 'test/**/*_test.rb'
  t.options = '--documentation'
  t.warning = false
end

Rake::TestTask.new(:test_rails) do |t|
  t.libs = %w(lib test_rails)
  t.pattern = 'test_rails/**/*_test.rb'
  t.warning = false
end

task default: [:spec, :test, :test_rails]
