# frozen_string_literal: true

require "rake"
require "bundler/gem_tasks"
require "rspec/core/rake_task"
Dir["lib/tasks/*.rake"].each { |rake| load rake }

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rspec_opts = ['--backtrace']
end

if ENV['TRAVIS'] && ENV['QUALITY'] == 'false'
  task default: 'spec'
elsif RUBY_VERSION > '1.9' && defined?(RUBY_ENGINE) && RUBY_ENGINE == 'ruby'
  task default: 'spec:quality'
else
  task default: 'spec'
end
