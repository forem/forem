$LOAD_PATH.unshift "./lib"
require 'rspec/mocks'
require "rspec/mocks/standalone"

=begin
This benchmark script is for troubleshooting the performance of
#264. To use it, you have to edit the code in #264 a bit:
wrap the call in `MethodDouble#initialize` to `find_original_method`
in a conditional like `if $find_original`.

That allows the code below to compare the perf of stubbing a method
with the original method being found vs. not.
=end

require 'benchmark'

n = 10_000

Foo = Class.new(Object) do
  n.times do |i|
    define_method "meth_#{i}" do
    end
  end
end

Benchmark.bmbm do |bm|
  puts "#{n} times - ruby #{RUBY_VERSION}"

  perform_report = lambda do |label, find_original, &create_object|
    dbl = create_object.call
    $find_original = find_original

    bm.report(label) do
      n.times do |i|
        dbl.stub("meth_#{i}")
      end
    end

    RSpec::Mocks.space.reset_all
  end

  perform_report.call("Find original - partial mock", true) { Foo.new }
  perform_report.call("Don't find original - partial mock", false) { Foo.new }
  perform_report.call("Find original - test double", true) { double }
  perform_report.call("Don't find original - test double", false) { double }
end

=begin

10000 times - ruby 1.9.3
Rehearsal ----------------------------------------------------------------------
Don't find original - partial mock   1.050000   0.020000   1.070000 (  1.068561)
Don't find original - test double    1.190000   0.010000   1.200000 (  1.199815)
Find original - partial mock         1.270000   0.010000   1.280000 (  1.282944)
Find original - test double          1.320000   0.020000   1.340000 (  1.336136)
------------------------------------------------------------- total: 4.890000sec

                                         user     system      total        real
Don't find original - partial mock   0.990000   0.000000   0.990000 (  1.000959)
Don't find original - test double    0.930000   0.010000   0.940000 (  0.931871)
Find original - partial mock         1.040000   0.000000   1.040000 (  1.046354)
Find original - test double          0.980000   0.010000   0.990000 (  0.983577)

=end
