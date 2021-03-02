$LOAD_PATH.unshift File.expand_path("../../../lib", __FILE__)
require 'rspec/core'
require 'allocation_stats'

def benchmark_allocations(burn: 1, min_allocations: 0)
  stats = AllocationStats.new(burn: burn).trace do
    yield
  end

  columns = if ENV['DETAIL']
              [:sourcefile, :sourceline, :class_plus]
            else
              [:class_plus]
            end

  results = stats.allocations(alias_paths: true).group_by(*columns).from_pwd.sort_by_size.to_text
  count_regex = /\s+(\d+)\z/

  total_objects = results.split("\n").map { |line| line[count_regex, 1] }.compact.map { |c| Integer(c) }.inject(0, :+)

  filtered = results.split("\n").select do |line|
    count = line[count_regex, 1]
    count.nil? || Integer(count) >= min_allocations
  end

  puts filtered.join("\n")
  line_length = filtered.last.length
  puts "-" * line_length
  puts "Total:#{total_objects.to_s.rjust(line_length - "Total:".length)}"
end
