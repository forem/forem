require "bundler"
Bundler::GemHelper.install_tasks

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

task test: :spec

require "rubocop/rake_task"
RuboCop::RakeTask.new

require "yard"
YARD::Rake::YardocTask.new do |task|
  task.files = ["lib/**/*.rb", "-", "LICENSE.md"]
  task.options = [
    "--no-private",
    "--protected",
    "--output-dir", "doc/yard",
    "--markup", "markdown"
  ]
end

require "yardstick/rake/measurement"
Yardstick::Rake::Measurement.new do |measurement|
  measurement.output = "measurement/report.txt"
end

require "yardstick/rake/verify"
Yardstick::Rake::Verify.new do |verify|
  verify.threshold = 48.8
end

task default: %i[spec rubocop verify_measurements]
