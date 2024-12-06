# frozen_string_literal: true

require 'json'
module Heapy
  # Diff 2 dumps example:
  #
  #   Heapy::Diff.new(before: 'my_dump_1.json', after: 'my_dump_2.json').call
  #
  # This will find objects that are present in my_dump_2 that are not present in my_dump_1
  # this means they were allocated sometime between the two heap dumps.
  #
  # Diff 3 dumps example:
  #
  #   Heapy::Diff.new(before: 'my_dump_1.json', after: 'my_dump_2.json', retained: 'my_dump_3.json').call
  #
  # This will find objects that are present in my_dump_2 that are not present in my_dump_1
  # but only if the objects are still present at the time that my_dump_3 was taken. This does
  # not guarantee that they're retained forever, but were still present at the time the last
  # dump was taken.
  #
  # You can output the diff of heap dumps by passing in a filename as `output_diff` for example
  #
  #   Heapy::Diff.new(before: 'my_dump_1.json', after: 'my_dump_2.json', outpu_diff: 'out.json').call
  class Diff
    attr_reader :diff

    def initialize(before:, after:, retained: nil, io: STDOUT, output_diff: nil)
      @before_file = before
      @after_file = after
      @retained_file = retained
      @output_diff_file = output_diff ? File.open(output_diff, "w+") : nil
      @io = io
      @diff = Hash.new { |hash, k|
        hash[k] = {}
        hash[k]["count"] = 0
        hash[k]["memsize"] = 0
        hash[k]
      }

      @before_address_hash = {}
      @retained_address_hash = {}
    end


    def call
      read(@before_file) { |parsed| @before_address_hash[parsed['address']] = true }
      read(@retained_file) { |parsed| @retained_address_hash[parsed['address']] = true } if @retained_file

      read(@after_file) do |parsed, original_line|
        address = parsed['address']
        next if previously_allocated?(address)
        next if not_retained?(address)

        @output_diff_file.puts original_line if @output_diff_file

        hash = diff["#{parsed['type']},#{parsed['file']},#{parsed['line']}"]
        hash["count"] += 1
        hash["memsize"] += parsed["memsize"] || 0
        hash["type"] ||= parsed["type"]
        hash["file"] ||= parsed["file"]
        hash["line"] ||= parsed["line"]
      end

      @output_diff_file.close if @output_diff_file
      @before_address_hash.clear
      @retained_address_hash.clear

      total_memsize = diff.inject(0){|sum,(_,v)| sum + v["memsize"] }

      diff.sort_by do |k,v|
        v["count"]
      end.reverse.each do |key, data|
        @io.puts "#{@retained_file ? "Retained" : "Allocated"} #{data['type']} #{data['count']} objects of size #{data['memsize']}/#{total_memsize} (in bytes) at: #{data['file']}:#{data['line']}"
      end

      @io.puts "\nWriting heap dump diff to #{@output_diff_file.path}\n" if @output_diff_file
    end

    private def is_retained?(address)
      return true if @retained_file.nil?
      @retained_address_hash[address]
    end

    private def not_retained?(address)
      !is_retained?(address)
    end

    private def previously_allocated?(address)
      @before_address_hash[address]
    end

    private def read(filename)
      File.open(filename) do |f|
        f.each_line do |line|
          begin
            parsed = JSON.parse(line)
            yield parsed, line
          rescue JSON::ParserError
            puts "Could not parse #{line}"
          end
        end
      end
    end
  end
end
