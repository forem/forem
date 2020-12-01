require_relative "helper"

1.upto(10) do |i|
  RSpec.shared_context "context #{i}", :apply_it do
  end
end

BenchmarkHelpers.run_benchmarks
# BenchmarkHelpers.profile(1000)

__END__

No match -- without singleton group support
                        563.304  (±29.6%) i/s -      2.385k
No match -- with singleton group support
                        538.738  (±22.3%) i/s -      2.209k
Example match -- without singleton group support
                        546.605  (±25.6%) i/s -      2.450k
Example match -- with singleton group support
                        421.111  (±23.5%) i/s -      1.845k
Group match -- without singleton group support
                        536.267  (±27.4%) i/s -      2.050k
Group match -- with singleton group support
                        508.644  (±17.7%) i/s -      2.268k
Both match -- without singleton group support
                        538.047  (±27.7%) i/s -      2.067k in   5.431649s
Both match -- with singleton group support
                        505.388  (±26.7%) i/s -      1.880k in   5.578614s
