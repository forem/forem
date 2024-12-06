require "bundler/gem_tasks"
require "rake/testtask"

$LOAD_PATH.unshift File.expand_path("./lib", __dir__)

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :default => :test


task :bench do
  require 'benchmark/ips'
  require 'enumerable/statistics'
  require 'mini_histogram'

  array = 1000.times.map { rand }

  histogram = MiniHistogram.new(array)
  my_weights = histogram.weights
  puts array.histogram.weights == my_weights
  puts array.histogram.weights.inspect
  puts my_weights.inspect


  Benchmark.ips do |x|
    x.report("enumerable stats") { array.histogram }
    x.report("mini histogram  ") {
      MiniHistogram.new(array).weights
    }
    x.compare!
  end
end
