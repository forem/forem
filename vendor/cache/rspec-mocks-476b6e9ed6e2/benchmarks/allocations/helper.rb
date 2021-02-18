$LOAD_PATH.unshift File.expand_path("../../../lib", __FILE__)
require "allocation_stats"
require 'rspec/mocks/standalone'

def benchmark_allocations(burn: 1)
  stats = AllocationStats.new(:burn => burn).trace do
    yield
  end

  columns = if ENV['DETAIL']
              [:sourcefile, :sourceline, :class_plus]
            else
              [:class_plus]
            end

  puts stats.allocations(:alias_paths => true).group_by(*columns).from_pwd.sort_by_size.to_text
end
