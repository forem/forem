require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'yard'
require 'open3'
require_relative 'lib/tasks/generate_huffman_table'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.exclude_pattern = './spec/hpack_test_spec.rb'
end

RSpec::Core::RakeTask.new(:hpack) do |t|
  t.pattern = './spec/hpack_test_spec.rb'
end

task :h2spec do
  if /darwin/ !~ RUBY_PLATFORM
    abort "h2spec rake task currently only works on OSX.
           Download other binaries from https://github.com/summerwind/h2spec/releases"
  end

  system 'ruby example/server.rb -p 9000 &', out: File::NULL
  sleep 1

  output = ''
  Open3.popen2e('spec/h2spec/h2spec.darwin -p 9000 -o 1') do |_i, oe, _t|
    oe.each do |l|
      l.gsub!(/\e\[(\d+)(;\d+)*m/, '')

      output << l
      if l =~ /passed.*failed/
        puts "\n#{l}"
        break # suppress post-summary failure output
      else
        print '.'
      end
    end
  end

  File.write 'spec/h2spec/output/non_secure.txt', output

  system 'kill `pgrep -f example/server.rb`'
end

RuboCop::RakeTask.new
YARD::Rake::YardocTask.new

task default: [:spec, :rubocop]
task all: [:default, :hpack]
