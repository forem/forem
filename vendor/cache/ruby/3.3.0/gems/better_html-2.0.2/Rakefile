# frozen_string_literal: true

begin
  require "bundler/setup"
  require "bundler/gem_tasks"
rescue LoadError
  puts "You must `gem install bundler` and `bundle install` to run rake tasks"
end

require "rake/extensiontask"
require "ruby_memcheck"

RubyMemcheck.config(binary_name: "better_html_ext")
Rake::ExtensionTask.new("better_html_ext")

require "rdoc/task"

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.title    = "BetterHtml"
  rdoc.options << "--line-numbers"
  rdoc.rdoc_files.include("README.rdoc")
  rdoc.rdoc_files.include("lib/**/*.rb")
end

require "rake/testtask"

test_config = lambda do |t|
  t.libs << "lib"
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
  t.verbose = false
end
Rake::TestTask.new(test: :compile, &test_config)
namespace :test do
  RubyMemcheck::TestTask.new(valgrind: :compile, &test_config)
end

task default: [:compile, :test]
