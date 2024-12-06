require "nenv"
require "bundler/gem_tasks"
require "yaml"

default_tasks = []

require "rspec/core/rake_task"
default_tasks << RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = Nenv.ci?
end

unless Nenv.ci?
  require "rubocop/rake_task"
  default_tasks << RuboCop::RakeTask.new(:rubocop)
end

task default: default_tasks.map(&:name)

namespace :test do
  desc "Locally run tests like Travis and HoundCI would"
  task :all_versions do
    system(*%w(bundle install --quiet)) || abort
    system(*%w(bundle update --quiet)) || abort
    system(*%w(bundle exec rubocop -c .rubocop.yml)) || abort

    travis = YAML.load(IO.read(".travis.yml"))
    travis["gemfile"].each do |gemfile|
      STDOUT.puts
      STDOUT.puts "----------------------------------------------------- "
      STDOUT.puts " >> Running tests using Gemfile: #{gemfile} <<"
      STDOUT.puts "----------------------------------------------------- "
      env = { "BUNDLE_GEMFILE" => gemfile }
      system(env, *%w(bundle install --quiet)) || abort
      system(env, *%w(bundle update --quiet)) || abort
      system(env, *%w(bundle exec rspec)) || abort
    end
  end
end
