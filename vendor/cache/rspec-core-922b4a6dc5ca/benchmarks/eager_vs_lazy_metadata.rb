require 'benchmark'

# preload rspec since we don't want to benchmark that.
require 'rspec/core'
require 'rspec/mocks'
require 'rspec/expectations'

def run_benchmark(description, *args)
  Benchmark.benchmark do |bm|
    3.times.each do
      bm.report(description) do
        pid = fork do
          RSpec::Core::Runner.run([
            # This file defines 16250 examples at various levels of nesting.
            "./benchmarks/eager_vs_lazy_metadata/define_examples.rb",
            *args
          ], StringIO.new, StringIO.new)

          exit!
        end

        # writeme.close
        Process.wait(pid)
      end
    end
  end
end

puts "#{RUBY_VERSION} - #{RSpec::Core::Metadata < Hash ? "lazy" : "eager"}"

run_benchmark("progress formatter, all", "-fp")
run_benchmark("documentation formatter, all", "-fd")
run_benchmark("progress formatter, filtering by example", "-fp", "-e", "nested")
run_benchmark("documentation formatter, filtering by example", "-fd", "-e", "nested")

__END__

On 2.1, precomputing metadata appears to be about 15% faster.

2.1.0 - eager
progress formatter, all  0.000000   0.000000   1.690000 (  1.700527)
progress formatter, all  0.000000   0.000000   1.710000 (  1.712091)
progress formatter, all  0.000000   0.000000   1.690000 (  1.694437)
documentation formatter, all  0.000000   0.000000   1.740000 (  1.752185)
documentation formatter, all  0.000000   0.000000   1.740000 (  1.743691)
documentation formatter, all  0.000000   0.010000   1.760000 (  1.752427)
progress formatter, filtering by example  0.000000   0.000000   1.710000 (  1.712782)
progress formatter, filtering by example  0.000000   0.000000   1.690000 (  1.695519)
progress formatter, filtering by example  0.000000   0.000000   1.680000 (  1.688278)
documentation formatter, filtering by example  0.000000   0.000000   1.740000 (  1.734581)
documentation formatter, filtering by example  0.000000   0.000000   1.720000 (  1.730275)
documentation formatter, filtering by example  0.000000   0.000000   1.730000 (  1.729879)

2.1.0 - lazy
progress formatter, all  0.000000   0.010000   2.020000 (  2.021899)
progress formatter, all  0.000000   0.000000   2.010000 (  2.013904)
progress formatter, all  0.000000   0.000000   1.990000 (  2.004857)
documentation formatter, all  0.000000   0.000000   2.120000 (  2.119586)
documentation formatter, all  0.000000   0.000000   2.120000 (  2.122598)
documentation formatter, all  0.000000   0.000000   2.110000 (  2.115573)
progress formatter, filtering by example  0.000000   0.000000   2.080000 (  2.081120)
progress formatter, filtering by example  0.000000   0.000000   2.050000 (  2.066418)
progress formatter, filtering by example  0.000000   0.000000   2.090000 (  2.085655)
documentation formatter, filtering by example  0.000000   0.010000   2.160000 (  2.166207)
documentation formatter, filtering by example  0.000000   0.000000   2.200000 (  2.196856)
documentation formatter, filtering by example  0.000000   0.000000   2.170000 (  2.172799)

On 2.0, precomputing metadata appears to be about 20% faster.

2.0.0 - eager
progress formatter, all  0.000000   0.000000   1.720000 (  1.730478)
progress formatter, all  0.000000   0.000000   1.710000 (  1.708679)
progress formatter, all  0.000000   0.000000   1.750000 (  1.753906)
documentation formatter, all  0.000000   0.000000   1.790000 (  1.804745)
documentation formatter, all  0.010000   0.010000   1.830000 (  1.805737)
documentation formatter, all  0.000000   0.000000   1.780000 (  1.802866)
progress formatter, filtering by example  0.000000   0.000000   1.720000 (  1.714562)
progress formatter, filtering by example  0.000000   0.000000   1.660000 (  1.663136)
progress formatter, filtering by example  0.000000   0.000000   1.710000 (  1.716405)
documentation formatter, filtering by example  0.000000   0.000000   1.760000 (  1.756188)
documentation formatter, filtering by example  0.000000   0.000000   1.760000 (  1.779646)
documentation formatter, filtering by example  0.000000   0.010000   1.780000 (  1.766562)

2.0.0 - lazy
progress formatter, all  0.000000   0.000000   2.140000 (  2.144684)
progress formatter, all  0.000000   0.000000   2.140000 (  2.152171)
progress formatter, all  0.000000   0.000000   2.150000 (  2.156945)
documentation formatter, all  0.000000   0.000000   2.270000 (  2.276520)
documentation formatter, all  0.000000   0.000000   2.270000 (  2.271053)
documentation formatter, all  0.000000   0.000000   2.280000 (  2.274769)
progress formatter, filtering by example  0.000000   0.000000   2.210000 (  2.222937)
progress formatter, filtering by example  0.000000   0.000000   2.190000 (  2.195851)
progress formatter, filtering by example  0.000000   0.000000   2.240000 (  2.251092)
documentation formatter, filtering by example  0.000000   0.010000   2.380000 (  2.368707)
documentation formatter, filtering by example  0.000000   0.000000   2.390000 (  2.405561)
documentation formatter, filtering by example  0.000000   0.000000   2.430000 (  2.422848)

On 1.9.3 it appears to be a wash.

1.9.3 - eager
progress formatter, all  0.000000   0.000000   1.860000 (  1.862991)
progress formatter, all  0.000000   0.000000   1.930000 (  1.940352)
progress formatter, all  0.000000   0.010000   1.860000 (  1.854856)
documentation formatter, all  0.000000   0.000000   1.900000 (  1.912110)
documentation formatter, all  0.000000   0.000000   2.000000 (  1.998096)
documentation formatter, all  0.000000   0.000000   1.910000 (  1.914563)
progress formatter, filtering by example  0.000000   0.000000   1.800000 (  1.800767)
progress formatter, filtering by example  0.000000   0.000000   1.900000 (  1.918205)
progress formatter, filtering by example  0.000000   0.000000   1.830000 (  1.824907)
documentation formatter, filtering by example  0.000000   0.000000   1.850000 (  1.855187)
documentation formatter, filtering by example  0.000000   0.000000   1.940000 (  1.945985)
documentation formatter, filtering by example  0.000000   0.010000   1.880000 (  1.879237)

1.9.3 - lazy
progress formatter, all  0.000000   0.000000   1.950000 (  1.953861)
progress formatter, all  0.000000   0.000000   1.840000 (  1.848092)
progress formatter, all  0.000000   0.000000   1.920000 (  1.930265)
documentation formatter, all  0.000000   0.000000   1.920000 (  1.922012)
documentation formatter, all  0.000000   0.000000   2.010000 (  2.012511)
documentation formatter, all  0.000000   0.000000   1.920000 (  1.921090)
progress formatter, filtering by example  0.000000   0.010000   1.990000 (  1.986591)
progress formatter, filtering by example  0.000000   0.000000   1.990000 (  1.986991)
progress formatter, filtering by example  0.000000   0.000000   1.990000 (  1.991256)
documentation formatter, filtering by example  0.000000   0.000000   2.070000 (  2.080637)
documentation formatter, filtering by example  0.000000   0.000000   2.030000 (  2.041768)
documentation formatter, filtering by example  0.000000   0.000000   1.970000 (  1.974151)
