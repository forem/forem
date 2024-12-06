require 'bundler/gem_tasks'
require 'rake/testtask'
# require 'yard'

task :test do
  Rake::TestTask.new do |t|
    t.libs.push "lib"
    t.test_files = FileList[File.expand_path('../test/**/*_test.rb', __FILE__)]
    t.verbose = true
  end
end

# task :doc do
#  YARD::CLI::Yardoc.new.run
# end