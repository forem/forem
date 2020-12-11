require 'benchmark'

n = 1_000_000

puts "each sample runs #{n} times"
puts

class Foo
  define_method :foo do
    @foo
  end

  attr_reader :bar

  def initialize
    @foo = 'foo'
    @bar = 'bar'
    @baz = 'baz'
  end

  def baz
    @baz
  end
end

foo = Foo.new

puts "define_method"
Benchmark.benchmark do |bm|
  3.times do
    bm.report do
      n.times do
        foo.foo
      end
    end
  end
end

puts
puts "attr_reader"
Benchmark.benchmark do |bm|
  3.times do
    bm.report do
      n.times do
        foo.bar
      end
    end
  end
end

puts
puts "def"
Benchmark.benchmark do |bm|
  3.times do
    bm.report do
      n.times do
        foo.baz
      end
    end
  end
end

# $ ruby -v
# ruby 1.9.2p290 (2011-07-09 revision 32553) [x86_64-darwin11.0.0]
# $ ruby benchmarks/define_method_v_attr_reader_v_def.rb
# each sample runs 1000000 times
#
# define_method
#   0.250000   0.000000   0.250000 (  0.251552)
#   0.250000   0.000000   0.250000 (  0.261506)
#   0.250000   0.000000   0.250000 (  0.247398)
#
# attr_reader
#   0.140000   0.000000   0.140000 (  0.141782)
#   0.140000   0.000000   0.140000 (  0.142411)
#   0.140000   0.000000   0.140000 (  0.145876)
#
# def
#   0.160000   0.000000   0.160000 (  0.153261)
#   0.150000   0.000000   0.150000 (  0.158096)
#   0.150000   0.000000   0.150000 (  0.149472)
