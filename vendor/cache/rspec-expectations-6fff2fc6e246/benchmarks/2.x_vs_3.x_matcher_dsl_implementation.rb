$LOAD_PATH.unshift "./lib"
require 'benchmark'
require 'rspec/expectations'

include RSpec::Expectations
include RSpec::Matchers

n = 1000

puts "3 runs of #{n} times for each example running rspec-expectations #{RSpec::Expectations::Version::STRING} -- #{RUBY_ENGINE}/#{RUBY_VERSION}"

puts "Defining a custom matcher"
Benchmark.benchmark do |bm|
  3.times do |i|
    bm.report do
      n.times do |j|
        RSpec::Matchers.define :"define_matcher_#{i}_#{j}" do
          match {}
        end
      end
    end
  end
end

puts "Getting an instance of a custom matcher"
RSpec::Matchers.define :be_a_multiple_of do |x|
  match { |actual| (actual % x).zero? }
end

Benchmark.benchmark do |bm|
  3.times do
    bm.report do
      n.times do |i|
        be_a_multiple_of(i)
      end
    end
  end
end

puts "Using a previously gotten custom matcher instance -- positive match"
Benchmark.benchmark do |bm|
  1.upto(3) do |i|
    matcher = be_a_multiple_of(i)
    bm.report do
      n.times do |j|
        expect(i * j).to matcher
      end
    end
  end
end

puts "Using a previously gotten custom matcher instance -- negative match"
Benchmark.benchmark do |bm|
  2.upto(4) do |i|
    matcher = be_a_multiple_of(i)
    bm.report do
      n.times do |j|
        begin
          expect(1 + i * j).to matcher
        rescue RSpec::Expectations::ExpectationNotMetError
        end
      end
    end
  end
end

=begin

Results are below for:

- MRI 2.0.0, MRI 1.9.3, JRuby 1.7.4
- Against 2.14.3, 3.0.0.pre before matcher DSL rewrite, 3.0.0.pre after matcher DSL rewrite

Conclusions:

* Getting an instance of a custom matcher was insanely slow in 2.x,
  and it looks like the `making_declared_methods_public` hack for 1.8.6
  was the primary source of that. Without that, getting an instance of
  a matcher is ~20x faster. To see what changed between 2.14.3 and
  the commit used for this benchmark, go to:
  https://github.com/rspec/rspec-expectations/compare/v2.14.3...4c47e4c43ee6961c755d325e73181b1f5b6bf097#diff-a51020971ade2c87f1d5b93f20d711c7L6
* With our new custom matcher DSL, using a matcher is approximately
  the same perf. However, defining a matcher is a little bit faster,
  and getting an instance of an already defined matcher is about 10x faster.

Overall, this is definitely a net win.

Results:

3 runs of 1000 times for each example running rspec-expectations 2.14.3 -- ruby/2.0.0
Defining a custom matcher
   0.010000   0.000000   0.010000 (  0.004612)
   0.000000   0.000000   0.000000 (  0.004674)
   0.000000   0.000000   0.000000 (  0.004944)
Getting an instance of a custom matcher
   1.470000   0.010000   1.480000 (  1.472602)
   1.420000   0.000000   1.420000 (  1.426760)
   1.440000   0.000000   1.440000 (  1.442283)
Using a previously gotten custom matcher instance -- positive match
   0.000000   0.000000   0.000000 (  0.002213)
   0.000000   0.000000   0.000000 (  0.002019)
   0.000000   0.000000   0.000000 (  0.001884)
Using a previously gotten custom matcher instance -- negative match
   0.020000   0.000000   0.020000 (  0.019378)
   0.030000   0.000000   0.030000 (  0.027001)
   0.020000   0.010000   0.030000 (  0.022310)

3 runs of 1000 times for each example running rspec-expectations 2.14.3 -- ruby/1.9.3
Defining a custom matcher
    0.000000   0.000000   0.000000 (  0.004455)
   0.010000   0.000000   0.010000 (  0.004849)
   0.010000   0.000000   0.010000 (  0.010495)
Getting an instance of a custom matcher
    1.690000   0.010000   1.700000 (  1.696415)
   1.550000   0.000000   1.550000 (  1.556858)
   1.550000   0.000000   1.550000 (  1.554830)
Using a previously gotten custom matcher instance -- positive match
    0.000000   0.000000   0.000000 (  0.002161)
   0.000000   0.000000   0.000000 (  0.002038)
   0.010000   0.000000   0.010000 (  0.002091)
Using a previously gotten custom matcher instance -- negative match
    0.050000   0.010000   0.060000 (  0.060512)
   0.050000   0.000000   0.050000 (  0.064532)
   0.060000   0.010000   0.070000 (  0.062206)

3 runs of 1000 times for each example running rspec-expectations 2.14.3 -- jruby/1.9.3
Defining a custom matcher
    0.660000   0.010000   0.670000 (  0.299000)
   0.280000   0.000000   0.280000 (  0.178000)
   0.220000   0.010000   0.230000 (  0.143000)
Getting an instance of a custom matcher
    1.970000   0.030000   2.000000 (  1.389000)
   1.340000   0.030000   1.370000 (  0.907000)
   0.820000   0.030000   0.850000 (  0.795000)
Using a previously gotten custom matcher instance -- positive match
    0.110000   0.000000   0.110000 (  0.058000)
   0.050000   0.000000   0.050000 (  0.036000)
   0.030000   0.000000   0.030000 (  0.030000)
Using a previously gotten custom matcher instance -- negative match
    0.930000   0.010000   0.940000 (  0.474000)
   0.620000   0.000000   0.620000 (  0.376000)
   0.390000   0.000000   0.390000 (  0.279000)

3 runs of 1000 times for each example running rspec-expectations 3.0.0.pre (before DSL rewrite) -- ruby/2.0.0
Defining a custom matcher
   0.010000   0.000000   0.010000 (  0.004719)
   0.000000   0.000000   0.000000 (  0.004424)
   0.010000   0.000000   0.010000 (  0.005562)
Getting an instance of a custom matcher
   0.050000   0.000000   0.050000 (  0.059949)
   0.060000   0.000000   0.060000 (  0.058208)
   0.060000   0.010000   0.070000 (  0.067402)
Using a previously gotten custom matcher instance -- positive match
   0.010000   0.000000   0.010000 (  0.001696)
   0.000000   0.000000   0.000000 (  0.001558)
   0.000000   0.000000   0.000000 (  0.001488)
Using a previously gotten custom matcher instance -- negative match
   0.020000   0.000000   0.020000 (  0.021522)
   0.030000   0.000000   0.030000 (  0.027728)
   0.020000   0.000000   0.020000 (  0.026185)

3 runs of 1000 times for each example running rspec-expectations 3.0.0.pre (before DSL rewrite) -- ruby/1.9.3
Defining a custom matcher
    0.010000   0.000000   0.010000 (  0.004650)
   0.000000   0.000000   0.000000 (  0.004658)
   0.010000   0.000000   0.010000 (  0.011111)
Getting an instance of a custom matcher
    0.050000   0.010000   0.060000 (  0.047230)
   0.060000   0.000000   0.060000 (  0.065500)
   0.070000   0.000000   0.070000 (  0.073099)
Using a previously gotten custom matcher instance -- positive match
    0.000000   0.000000   0.000000 (  0.002007)
   0.000000   0.000000   0.000000 (  0.002370)
   0.010000   0.000000   0.010000 (  0.002121)
Using a previously gotten custom matcher instance -- negative match
    0.070000   0.010000   0.080000 (  0.078960)
   0.060000   0.000000   0.060000 (  0.061351)
   0.060000   0.000000   0.060000 (  0.069949)

3 runs of 1000 times for each example running rspec-expectations 3.0.0.pre (before DSL rewrite) -- jruby/1.9.3
Defining a custom matcher
    0.730000   0.010000   0.740000 (  0.303000)
   0.240000   0.010000   0.250000 (  0.153000)
   0.210000   0.000000   0.210000 (  0.140000)
Getting an instance of a custom matcher
    0.940000   0.010000   0.950000 (  0.538000)
   0.510000   0.000000   0.510000 (  0.174000)
   0.160000   0.000000   0.160000 (  0.090000)
Using a previously gotten custom matcher instance -- positive match
    0.120000   0.000000   0.120000 (  0.053000)
   0.040000   0.000000   0.040000 (  0.025000)
   0.030000   0.000000   0.030000 (  0.026000)
Using a previously gotten custom matcher instance -- negative match
    0.970000   0.010000   0.980000 (  0.458000)
   0.480000   0.010000   0.490000 (  0.314000)
   0.360000   0.000000   0.360000 (  0.269000)

3 runs of 1000 times for each example running rspec-expectations 3.0.0.pre -- ruby/2.0.0
Defining a custom matcher
   0.000000   0.000000   0.000000 (  0.003138)
   0.000000   0.000000   0.000000 (  0.003083)
   0.010000   0.000000   0.010000 (  0.003448)
Getting an instance of a custom matcher
   0.000000   0.000000   0.000000 (  0.007273)
   0.010000   0.000000   0.010000 (  0.007096)
   0.020000   0.000000   0.020000 (  0.021662)
Using a previously gotten custom matcher instance -- positive match
   0.000000   0.000000   0.000000 (  0.002582)
   0.000000   0.000000   0.000000 (  0.001832)
   0.010000   0.000000   0.010000 (  0.001588)
Using a previously gotten custom matcher instance -- negative match
   0.010000   0.000000   0.010000 (  0.017756)
   0.030000   0.000000   0.030000 (  0.021225)
   0.020000   0.010000   0.030000 (  0.021281)

3 runs of 1000 times for each example running rspec-expectations 3.0.0.pre -- ruby/1.9.3
Defining a custom matcher
    0.000000   0.000000   0.000000 (  0.002903)
   0.000000   0.000000   0.000000 (  0.002919)
   0.010000   0.000000   0.010000 (  0.008956)
Getting an instance of a custom matcher
    0.010000   0.000000   0.010000 (  0.006640)
   0.000000   0.000000   0.000000 (  0.006557)
   0.010000   0.000000   0.010000 (  0.007869)
Using a previously gotten custom matcher instance -- positive match
    0.010000   0.000000   0.010000 (  0.003332)
   0.000000   0.000000   0.000000 (  0.003288)
   0.000000   0.000000   0.000000 (  0.002769)
Using a previously gotten custom matcher instance -- negative match
    0.070000   0.010000   0.080000 (  0.075547)
   0.050000   0.000000   0.050000 (  0.053149)
   0.060000   0.010000   0.070000 (  0.062583)

3 runs of 1000 times for each example running rspec-expectations 3.0.0.pre -- jruby/1.9.3
Defining a custom matcher
    0.780000   0.020000   0.800000 (  0.316000)
   0.170000   0.010000   0.180000 (  0.139000)
   0.220000   0.000000   0.220000 (  0.135000)
Getting an instance of a custom matcher
    0.340000   0.000000   0.340000 (  0.183000)
   0.230000   0.010000   0.240000 (  0.131000)
   0.180000   0.000000   0.180000 (  0.104000)
Using a previously gotten custom matcher instance -- positive match
    0.170000   0.000000   0.170000 (  0.076000)
   0.070000   0.000000   0.070000 (  0.049000)
   0.110000   0.000000   0.110000 (  0.047000)
Using a previously gotten custom matcher instance -- negative match
    0.970000   0.010000   0.980000 (  0.461000)
   0.410000   0.000000   0.410000 (  0.316000)
   0.350000   0.010000   0.360000 (  0.256000)

=end
