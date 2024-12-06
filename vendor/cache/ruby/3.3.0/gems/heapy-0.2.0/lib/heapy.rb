require 'json'
require 'thor'

require "heapy/version"

module Heapy
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc "read <file> <generation> --lines <number_of_lines>", "Read heap dump file"
    long_desc <<-DESC
      When run with only a file input, it will output the generation and count pairs:

        $ heapy read tmp/2015-09-30-heap.dump\x5
          Generation: nil object count: 209191\x5
          Generation:  14 object count: 407\x5
          Generation:  15 object count: 638\x5
          Generation:  16 object count: 748\x5
          Generation:  17 object count: 1023\x5
          Generation:  18 object count: 805\x5

      When run with a file and a number it will output detailed information for that\x5
      generation:\x5

        $ heapy read tmp/2015-09-30-heap.dump 17\x5

          Analyzing Heap (Generation: 17)\x5
          -------------------------------\x5

      allocated by memory (44061517) (in bytes)\x5
      ==============================\x5
        39908512  /app/vendor/ruby-2.2.3/lib/ruby/2.2.0/timeout.rb:79\x5
         1284993  /app/vendor/ruby-2.2.3/lib/ruby/2.2.0/openssl/buffering.rb:182\x5
          201068  /app/vendor/bundle/ruby/2.2.0/gems/json-1.8.3/lib/json/common.rb:223\x5
          189272  /app/vendor/bundle/ruby/2.2.0/gems/newrelic_rpm-3.13.2.302/lib/new_relic/agent/stats_engine/stats_hash.rb:39\x5
          172531  /app/vendor/ruby-2.2.3/lib/ruby/2.2.0/net/http/header.rb:172\x5
           92200  /app/vendor/bundle/ruby/2.2.0/gems/activesupport-4.2.3/lib/active_support/core_ext/numeric/conversions.rb:131\x5
    DESC
    option :lines, required: false, :type => :numeric
    def read(file_name, generation = nil)
      if generation
        Analyzer.new(file_name).drill_down(generation, options[:lines] || 50)
      else
        Analyzer.new(file_name).analyze
      end
    end

    long_desc <<-DESC
      Run with two inputs to output the values of today.dump that are not present in yesterday.dump

        $ heapy diff tmp/yesterday.dump tmp/today.dump\x5

      Run with three inputs to show the diff between the first two, but only if the objects are still retained in the third

        $ heapy diff tmp/yesterday.dump tmp/today_morning.dump tmp/today_afternoon.dump\x5

      Pass in the name of an output file and the objects present in today.dump that aren't in yesterday.dump will be written to that file

        $ heapy diff tmp/yesterday.dump tmp/today.dump --output_diff=output.json\x5

    DESC
    desc "diff <before_file> <after_file> <retained_file (optional)> --output_diff=output.json", "Diffs 2 heap dumps"
    option :output_diff, required: false, :type => :string
    def diff(before, after, retained = nil)
      Diff.new(before: before, after: after, retained: retained, output_diff: options[:output_diff] || nil).call
    end

    map %w[--version -v] => :version
    desc "version", "Show heapy version"
    def version
      puts Heapy::VERSION
    end

    desc "wat", "Outputs instructions on how to make a manual heap dump"
    def wat
      puts <<-HELP

To get a heap dump do this:

    require 'objspace'
    ObjectSpace.trace_object_allocations_start

    # Your code here

    p ObjectSpace.dump_all

    # => #<File:/path/to/output/heap/dump/here.json>

This will print the file name of your heap dump.

If you prefer you can manually pass in an IO object to `ObjectSpace.dump_all`

    io = File.open("/tmp/my_dump.json", "w+")
    ObjectSpace.dump_all(output: io);
    io.close

HELP
    end
  end
end

require 'heapy/analyzer'
require 'heapy/diff'
