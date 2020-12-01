require 'benchmark'

n = 1_000_000

Foo = Class.new do
  1.upto(n) do |i|
    define_method(:"public_method_#{i}") {}
    define_method(:"protected_method_#{i}") {}
    protected :"protected_method_#{i}"
    define_method(:"private_method_#{i}") {}
    private :"protected_method_#{i}"
  end
end

Benchmark.benchmark do |bm|
  puts "#{n} times - ruby #{RUBY_VERSION}"

  puts
  puts "using method_defined? and private_method_defined?"
  puts

  [:public, :protected, :private, :undefined].each do |vis|
    puts "  - #{vis} methods"

    3.times do
      GC.start

      bm.report do
        n.times do |i|
          name = :"#{vis}_method_#{i}"
          Foo.method_defined?(name) || Foo.private_method_defined?(name)
        end
      end
    end
  end

  puts
  puts "using public_method_defined?, protected_method_defined? and private_method_defined?"
  puts

  [:public, :protected, :private, :undefined].each do |vis|
    puts "  - #{vis} methods"

    3.times do
      GC.start

      bm.report do
        n.times do |i|
          name = :"#{vis}_method_#{i}"
          Foo.public_method_defined?(name) ||
          Foo.protected_method_defined?(name)
          Foo.private_method_defined?(name)
        end
      end
    end
  end
end

=begin

1000000 times - ruby 2.0.0

using method_defined? and private_method_defined?

  - public methods
   1.410000   0.040000   1.450000 (  1.462588)
   1.380000   0.000000   1.380000 (  1.372015)
   1.370000   0.000000   1.370000 (  1.372362)
  - protected methods
   1.410000   0.000000   1.410000 (  1.402750)
   1.440000   0.000000   1.440000 (  1.442719)
   1.460000   0.010000   1.470000 (  1.464763)
  - private methods
   1.390000   0.000000   1.390000 (  1.393956)
   1.340000   0.000000   1.340000 (  1.349340)
   1.360000   0.000000   1.360000 (  1.361910)
  - undefined methods
   3.260000   0.050000   3.310000 (  3.316372)
   1.260000   0.010000   1.270000 (  1.266557)
   1.250000   0.000000   1.250000 (  1.248734)

using public_method_defined?, protected_method_defined? and private_method_defined?

  - public methods
   1.550000   0.000000   1.550000 (  1.550655)
   1.540000   0.010000   1.550000 (  1.543906)
   1.540000   0.000000   1.540000 (  1.538267)
  - protected methods
   1.590000   0.000000   1.590000 (  1.598310)
   1.600000   0.000000   1.600000 (  1.595205)
   1.600000   0.000000   1.600000 (  1.604186)
  - private methods
   1.530000   0.000000   1.530000 (  1.530080)
   1.560000   0.000000   1.560000 (  1.562656)
   1.560000   0.000000   1.560000 (  1.569161)
  - undefined methods
   1.300000   0.000000   1.300000 (  1.298066)
   1.310000   0.000000   1.310000 (  1.310737)
   1.290000   0.000000   1.290000 (  1.288307)

=end
