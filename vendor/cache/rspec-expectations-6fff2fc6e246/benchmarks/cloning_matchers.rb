require 'benchmark'
require 'rspec/expectations'
include RSpec::Matchers

n = 1_000_000
matcher = eq(3)

Benchmark.bm do |x|
  x.report do
    n.times { matcher.clone }
  end
end

__END__

We can do about 1000 clones per ms:

      user     system      total        real
  1.080000   0.030000   1.110000 (  1.120009)
