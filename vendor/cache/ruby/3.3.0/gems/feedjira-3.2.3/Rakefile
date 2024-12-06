# frozen_string_literal: true

require "rspec/core/rake_task"
require "rubocop/rake_task"
require "yard"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = false
end

RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ["--display-cop-names"]
end

YARD::Rake::YardocTask.new do |t|
  t.files   = ["lib/**/*.rb", "-", "LICENSE"]
end

task default: %i[spec rubocop]
