$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))

require 'benchmark'
require 'rspec/mocks'

n = 1000

puts "#{n} times - ruby #{RUBY_VERSION}"
puts

Benchmark.bm do |bm|
  RSpec::Mocks.setup(self)

  (0..9).each do |m|
    attrs = m.times.inject({}) {|h, x|
      h["method_#{x}"] = x
      h
    }

    bm.report("#{m} attrs") do
      n.times do
        double(attrs)
      end
    end
  end
end
# $ export OLD_REV=d483e0a893d97c7b8e612e878a9f3562a210df9f
# $ git checkout $OLD_REV
# $ ruby benchmarks/double_creation.rb
# 1000 times - ruby 2.0.0
#
#           user     system      total        real
#    0 attrs  0.010000   0.000000   0.010000 (  0.003686)
#    1 attrs  0.110000   0.000000   0.110000 (  0.143132)
#    2 attrs  0.230000   0.010000   0.240000 (  0.311358)
#    3 attrs  0.400000   0.020000   0.420000 (  0.465994)
#    4 attrs  0.570000   0.010000   0.580000 (  0.597902)
#    5 attrs  0.920000   0.010000   0.930000 (  1.060219)
#    6 attrs  1.350000   0.020000   1.370000 (  1.388386)
#    7 attrs  1.770000   0.030000   1.800000 (  1.805518)
#    8 attrs  2.620000   0.030000   2.650000 (  2.681484)
#    9 attrs  3.320000   0.030000   3.350000 (  3.380757)
#
# $ export NEW_REV=13e9d11542a6b60c5dc7ffa4527c98bb255d0a1f
# $ git checkout $NEW_REV
# $ ruby benchmarks/double_creation.rb
# 1000 times - ruby 2.0.0
#
#             user     system      total        real
#    0 attrs  0.010000   0.000000   0.010000 (  0.001544)
#    1 attrs  0.040000   0.000000   0.040000 (  0.043522)
#    2 attrs  0.060000   0.000000   0.060000 (  0.081742)
#    3 attrs  0.090000   0.010000   0.100000 (  0.104526)
#    4 attrs  0.120000   0.010000   0.130000 (  0.132472)
#    5 attrs  0.150000   0.010000   0.160000 (  0.162368)
#    6 attrs  0.190000   0.010000   0.200000 (  0.204610)
#    7 attrs  0.220000   0.010000   0.230000 (  0.237983)
#    8 attrs  0.260000   0.010000   0.270000 (  0.281562)
#    9 attrs  0.310000   0.020000   0.330000 (  0.334489)
#
# $ git log $OLD_REV..$NEW_REV --oneline
# 13e9d11 Remove unused arguments from simple stub interface.
# 009a697 Extract CallerFilter class to unify caller manipulation.
# 46c1eb0 Introduce "simple" stub as an optimization over using a normal stub.
# 4a04b3e Extract constant ArgumentListMatcher::MATCH_ALL.
# 860d591 Speed up double creation with multiple attributes by caching caller.
