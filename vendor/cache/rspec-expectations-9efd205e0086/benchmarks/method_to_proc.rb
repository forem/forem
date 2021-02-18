require 'benchmark'

n = 10_000_000

puts "3 runs of #{n} times running #{RUBY_ENGINE}/#{RUBY_VERSION}"

def foo(x); end
def extract_method_proc(&b); b; end

Benchmark.benchmark do |bm|
  puts "calling foo = method(:foo).to_proc"
  foo_proc = method(:foo).to_proc

  3.times do
    bm.report do
      n.times { foo_proc.call(1) }
    end
  end

  puts "calling Proc.new { |x| foo(x) }"
  foo_proc = extract_method_proc { |x| foo(x) }

  3.times do
    bm.report do
      n.times { foo_proc.call(1) }
    end
  end
end

__END__

Surprisingly, `Method#to_proc` is slower, except on 1.9.3 where it's a wash.

3 runs of 10000000 times running ruby/2.1.1
calling foo = method(:foo).to_proc
   2.190000   0.010000   2.200000 (  2.206627)
   2.370000   0.010000   2.380000 (  2.391100)
   2.190000   0.000000   2.190000 (  2.193119)
calling Proc.new { |x| foo(x) }
   1.640000   0.000000   1.640000 (  1.648841)
   1.610000   0.000000   1.610000 (  1.617186)
   1.590000   0.010000   1.600000 (  1.600570)

3 runs of 10000000 times running ruby/2.0.0
calling foo = method(:foo).to_proc
   2.170000   0.010000   2.180000 (  2.192418)
   2.140000   0.000000   2.140000 (  2.141015)
   2.150000   0.010000   2.160000 (  2.172794)
calling Proc.new { |x| foo(x) }
   1.680000   0.000000   1.680000 (  1.686904)
   1.650000   0.000000   1.650000 (  1.654465)
   1.640000   0.000000   1.640000 (  1.648229)

3 runs of 10000000 times running ruby/1.9.3
 calling foo = method(:foo).to_proc
   2.440000   0.010000   2.450000 (  2.457211)
   2.430000   0.000000   2.430000 (  2.450140)
   2.480000   0.010000   2.490000 (  2.496520)
calling Proc.new { |x| foo(x) }
   2.400000   0.000000   2.400000 (  2.415641)
   2.480000   0.000000   2.480000 (  2.489564)
   2.460000   0.000000   2.460000 (  2.477368)

3 runs of 10000000 times running ruby/1.9.2
calling foo = method(:foo).to_proc
  2.490000   0.010000   2.500000 (  2.502401)
  2.580000   0.000000   2.580000 (  2.589306)
  2.310000   0.010000   2.320000 (  2.328342)
calling Proc.new { |x| foo(x) }
  1.860000   0.000000   1.860000 (  1.866537)
  1.860000   0.000000   1.860000 (  1.871056)
  1.850000   0.010000   1.860000 (  1.857426)
