require "bundler/gem_tasks"

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :test_all_gemfiles

module TestTasks
  module_function

  TEST_CMD = 'bundle exec rspec'

  def run_all(envs, cmd = "bundle install && #{TEST_CMD}", success_message)
    statuses = envs.map { |env| run(env, cmd) }
    failed   = statuses.reject(&:first).map(&:last)
    if failed.empty?
      $stderr.puts success_message
    else
      $stderr.puts "❌  FAILING (#{failed.size}):\n#{failed.map { |env| to_bash_cmd_with_env(cmd, env) } * "\n"}"
      exit 1
    end
  end

  def run_one(env, cmd = "bundle install && #{TEST_CMD}")
    full_cmd = to_bash_cmd_with_env(cmd, env)
    exec(full_cmd)
  end

  def run(env, cmd)
    Bundler.with_clean_env do
      full_cmd = to_bash_cmd_with_env(cmd, env)
      $stderr.puts full_cmd
      isSuccess = system(full_cmd)
      [isSuccess, env]
    end
  end

  def gemfiles
    Dir.glob('*.gemfile').sort
  end

  def to_bash_cmd_with_env(cmd, env)
    "(export #{env.map { |k, v| "#{k}=#{v}" }.join(' ')}; #{cmd})"
  end
end

desc 'Test all Gemfiles'
task :test_all_gemfiles do
  envs = TestTasks.gemfiles.map { |gemfile| { 'BUNDLE_GEMFILE' => gemfile } }
  TestTasks.run_all envs, "✓ Tests pass with all #{envs.size} gemfiles"
end


TestTasks.gemfiles.each do |gemfile|
  rails_version_underscored = gemfile[/rails_(.+)\.gemfile/, 1]

  desc "Test Rails #{rails_version_underscored.gsub("_", ".")}"
  task :"test_rails_#{rails_version_underscored}" do
    env = { 'BUNDLE_GEMFILE' => gemfile }
    TestTasks.run_one(env)
  end
end