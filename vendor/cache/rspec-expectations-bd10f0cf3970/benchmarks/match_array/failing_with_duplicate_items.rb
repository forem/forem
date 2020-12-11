$LOAD_PATH.unshift "./lib"
require 'benchmark'
require 'rspec/expectations'

extend RSpec::Matchers

sizes = [10, 100, 1000]

puts "rspec-expectations #{RSpec::Expectations::Version::STRING} -- #{RUBY_ENGINE}/#{RUBY_VERSION}"

puts
puts "Failing `match_array` expectation with lists of integers (w/dups) having 1 unmatched pair"
puts

Benchmark.benchmark do |bm|
  sizes.each do |size|
    actual    = Array.new(size) { rand(size / 2) }
    expecteds = Array.new(3) do
      array = actual.shuffle
      array[rand(array.length)] = 9_999_999
      array
    end

    expecteds.each do |expected|
      bm.report("#{size.to_s.rjust(5)} items") do
        begin
          expect(actual).to match_array(expected)
        rescue RSpec::Expectations::ExpectationNotMetError
        else
          raise "did not fail but should have"
        end
      end
    end
  end
end

__END__

Before new composable matchers algo:

   10 items  0.000000   0.000000   0.000000 (  0.000711)
   10 items  0.000000   0.000000   0.000000 (  0.000079)
   10 items  0.000000   0.000000   0.000000 (  0.000080)
   20 items  0.000000   0.000000   0.000000 (  0.000105)
   20 items  0.000000   0.000000   0.000000 (  0.000122)
   20 items  0.000000   0.000000   0.000000 (  0.000101)
   25 items  0.000000   0.000000   0.000000 (  0.000125)
   25 items  0.000000   0.000000   0.000000 (  0.000137)
   25 items  0.000000   0.000000   0.000000 (  0.000116)

After:

  This varies widly based on the inputs. One run:

     10 items  0.010000   0.000000   0.010000 (  0.005884)
     10 items  0.000000   0.000000   0.000000 (  0.004429)
     10 items  0.000000   0.000000   0.000000 (  0.004733)
     20 items  2.040000   0.000000   2.040000 (  2.049461)
     20 items  2.080000   0.010000   2.090000 (  2.087983)
     20 items  1.950000   0.000000   1.950000 (  1.950013)
     25 items 10.240000   0.020000  10.260000 ( 10.280575)
     25 items 10.390000   0.010000  10.400000 ( 10.433754)
     25 items 10.250000   0.020000  10.270000 ( 10.311604)

  Another run:

     10 items  0.010000   0.010000   0.020000 (  0.015355)
     10 items  0.010000   0.000000   0.010000 (  0.010347)
     10 items  0.020000   0.000000   0.020000 (  0.013657)
     20 items 36.140000   0.030000  36.170000 ( 36.236651)
     20 items 36.010000   0.040000  36.050000 ( 36.098006)
     20 items 35.990000   0.030000  36.020000 ( 36.071397)

  (I lost patience and didn't wait for it to finish 25 items...)

With "smaller subproblem" optimization: (way faster!)

   10 items  0.000000   0.000000   0.000000 (  0.001411)
   10 items  0.000000   0.000000   0.000000 (  0.000615)
   10 items  0.000000   0.000000   0.000000 (  0.000413)
   20 items  0.000000   0.000000   0.000000 (  0.000947)
   20 items  0.000000   0.000000   0.000000 (  0.001725)
   20 items  0.000000   0.000000   0.000000 (  0.001345)
   25 items  0.010000   0.000000   0.010000 (  0.002348)
   25 items  0.000000   0.000000   0.000000 (  0.002836)
   25 items  0.000000   0.000000   0.000000 (  0.002721)

With "implement `values_match?` ourselves" optimization: (about twice as fast!)

   10 items  0.000000   0.000000   0.000000 (  0.002450)
   10 items  0.000000   0.000000   0.000000 (  0.000857)
   10 items  0.000000   0.000000   0.000000 (  0.000883)
  100 items  0.040000   0.000000   0.040000 (  0.043661)
  100 items  0.060000   0.000000   0.060000 (  0.053046)
  100 items  0.040000   0.010000   0.050000 (  0.051760)
 1000 items  3.620000   0.060000   3.680000 (  3.688289)
 1000 items  2.600000   0.020000   2.620000 (  2.628405)
 1000 items  4.660000   0.040000   4.700000 (  4.712196)

With e === a || a == e || values_match?(e,a)

   10 items  0.000000   0.000000   0.000000 (  0.001992)
   10 items  0.000000   0.000000   0.000000 (  0.000821)
   10 items  0.000000   0.000000   0.000000 (  0.000794)
  100 items  0.060000   0.000000   0.060000 (  0.068597)
  100 items  0.060000   0.000000   0.060000 (  0.056409)
  100 items  0.070000   0.010000   0.080000 (  0.072950)
 1000 items  4.090000   0.100000   4.190000 (  4.218107)
 1000 items  3.000000   0.050000   3.050000 (  3.070019)
 1000 items  6.040000   0.070000   6.110000 (  6.102311)

With values_match?(e,a)

   10 items  0.000000   0.000000   0.000000 (  0.002177)
   10 items  0.000000   0.000000   0.000000 (  0.001201)
   10 items  0.000000   0.000000   0.000000 (  0.000928)
  100 items  0.050000   0.000000   0.050000 (  0.051785)
  100 items  0.040000   0.000000   0.040000 (  0.032323)
  100 items  0.040000   0.000000   0.040000 (  0.046934)
 1000 items  4.050000   0.100000   4.150000 (  4.175914)
 1000 items  3.040000   0.050000   3.090000 (  3.130656)
 1000 items  4.110000   0.050000   4.160000 (  4.161170)
