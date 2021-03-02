require 'benchmark'

$t = 3
$n = 100000

def report(header)
  puts header
  reals = []
  Benchmark.bm do |bm|
    $t.times do
      reals << bm.report { $n.times { yield } }.real
    end
  end

  [header, (reals.inject(&:+) / reals.count).round(5)]
end

multi = [
  /\/lib\d*\/ruby\//,
  /org\/jruby\//,
  /bin\//,
  %r|/gems/|,
  /lib\/rspec\/(core|expectations|matchers|mocks)/
]

union = [Regexp.union(multi)]

avgs = []

avgs << report("multi w/ match") {
  multi.any? {|e| e =~ "lib/rspec/core"}
}

avgs << report("union w/ match") {
  union.any? {|e| e =~ "lib/rspec/core"}
}

avgs << report("multi w/ no match") {
  multi.any? {|e| e =~ "foo/bar"}
}

avgs << report("union w/ no match") {
  union.any? {|e| e =~ "foo/bar"}
}

puts

avgs.each do |header, val|
  puts header, val
  puts
end

__END__

multi w/ match
       user     system      total        real
   0.400000   0.000000   0.400000 (  0.405063)
   0.410000   0.000000   0.410000 (  0.402778)
   0.430000   0.000000   0.430000 (  0.435447)
union w/ match
       user     system      total        real
   0.130000   0.000000   0.130000 (  0.127526)
   0.130000   0.000000   0.130000 (  0.135529)
   0.130000   0.000000   0.130000 (  0.127866)
multi w/ no match
       user     system      total        real
   0.320000   0.000000   0.320000 (  0.318921)
   0.330000   0.000000   0.330000 (  0.328375)
   0.340000   0.000000   0.340000 (  0.341230)
union w/ no match
       user     system      total        real
   0.170000   0.000000   0.170000 (  0.175144)
   0.170000   0.000000   0.170000 (  0.168816)
   0.170000   0.000000   0.170000 (  0.168362)

multi w/ match
0.41443

union w/ match
0.13031

multi w/ no match
0.32951

union w/ no match
0.17077
