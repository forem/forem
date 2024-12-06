require 'bundler'
require 'rdoc/task'
require 'rake/testtask'

task :default => :test

Bundler::GemHelper.install_tasks

RDoc::Task.new do |task|
  task.rdoc_dir = 'doc'
  task.title    = 'BufferedTokenizer'
  task.rdoc_files.include('lib/**/*.rb')
end

Rake::TestTask.new :test do |t|
  t.libs << 'lib'
  t.test_files = FileList['test/**/*.rb']
end

desc "Benchmark the current implementation"
task :bench do
  require 'benchmark'
  require File.expand_path('lib/buftok', File.dirname(__FILE__))

  n = 50000
  delimiter = "\n\n"

  frequency1 = 1000
  puts "generating #{n} strings, with #{delimiter.inspect} every #{frequency1} strings..."
  data1 = (0...n).map do |i|
    (((i % frequency1 == 1) ? "\n" : "") +
      ("s" * i) +
      ((i % frequency1 == 0) ? "\n" : "")).freeze
  end

  frequency2 = 10
  puts "generating #{n} strings, with #{delimiter.inspect} every #{frequency2} strings..."
  data2 = (0...n).map do |i|
    (((i % frequency2 == 1) ? "\n" : "") +
      ("s" * i) +
      ((i % frequency2 == 0) ? "\n" : "")).freeze
  end

  Benchmark.bmbm do |x|
    x.report("1 char, freq: #{frequency1}") do
      bt1 = BufferedTokenizer.new
      n.times { |i| bt1.extract(data1[i]) }
    end

    x.report("2 char, freq: #{frequency1}") do
      bt2 = BufferedTokenizer.new(delimiter)
      n.times { |i| bt2.extract(data1[i]) }
    end

    x.report("1 char, freq: #{frequency2}") do
      bt3 = BufferedTokenizer.new
      n.times { |i| bt3.extract(data2[i]) }
    end

    x.report("2 char, freq: #{frequency2}") do
      bt4 = BufferedTokenizer.new(delimiter)
      n.times { |i| bt4.extract(data2[i]) }
    end

  end
end
