require 'benchmark'
require 'set'

n = 10_000_000

array = [
  :@name, :@declarations, :@diffable, :@messages,
  :@match_block, :@match_for_should_not_block,
  :@expected_exception
]
set = array.to_set

puts "Positive examples: "
Benchmark.bm(25) do |x|
  array.each_with_index do |var, i|
    x.report("set.include?(item #{i})  ") do
      n.times { set.include?(var) }
    end

    x.report("array.include?(item #{i})") do
      n.times { array.include?(var) }
    end

    puts "=" * 80
  end
end

puts "\n\nNegative examples: "
Benchmark.bm(5) do |x|
  x.report("set  ") do
    n.times { set.include?(:@other) }
  end

  x.report("array") do
    n.times { array.include?(:@other) }
  end
end

# Positive examples:
#                                user     system      total        real
# set.include?(item 0)       2.000000   0.010000   2.010000 (  1.999305)
# array.include?(item 0)     1.170000   0.000000   1.170000 (  1.173168)
# ================================================================================
# set.include?(item 1)       2.020000   0.000000   2.020000 (  2.016389)
# array.include?(item 1)     1.580000   0.000000   1.580000 (  1.585301)
# ================================================================================
# set.include?(item 2)       1.980000   0.010000   1.990000 (  1.984699)
# array.include?(item 2)     2.170000   0.000000   2.170000 (  2.167163)
# ================================================================================
# set.include?(item 3)       2.110000   0.010000   2.120000 (  2.125914)
# array.include?(item 3)     2.450000   0.000000   2.450000 (  2.445224)
# ================================================================================
# set.include?(item 4)       2.090000   0.010000   2.100000 (  2.094182)
# array.include?(item 4)     2.920000   0.000000   2.920000 (  2.924850)
# ================================================================================
# set.include?(item 5)       2.000000   0.000000   2.000000 (  2.000656)
# array.include?(item 5)     3.540000   0.010000   3.550000 (  3.547563)
# ================================================================================
# set.include?(item 6)       2.030000   0.000000   2.030000 (  2.032430)
# array.include?(item 6)     3.800000   0.010000   3.810000 (  3.810014)
# ================================================================================

# Negative examples:
#            user     system      total        real
# set    1.940000   0.000000   1.940000 (  1.941780)
# array  4.240000   0.010000   4.250000 (  4.238137)
