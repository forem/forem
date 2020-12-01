require_relative "helper"

RSpec.configure do |c|
  1.upto(10) do
    c.include Module.new, :apply_it
  end
end

BenchmarkHelpers.run_benchmarks

__END__

No match -- without singleton group support
                        555.498  (±27.0%) i/s -      2.496k
No match -- with singleton group support
                        529.826  (±23.0%) i/s -      2.397k in   5.402305s
Example match -- without singleton group support
                        541.845  (±29.0%) i/s -      2.208k
Example match -- with singleton group support
                        465.440  (±20.4%) i/s -      2.091k
Group match -- without singleton group support
                        530.976  (±24.1%) i/s -      2.303k
Group match -- with singleton group support
                        505.291  (±18.8%) i/s -      2.226k
Both match -- without singleton group support
                        542.168  (±28.4%) i/s -      2.067k in   5.414905s
Both match -- with singleton group support
                        503.226  (±27.2%) i/s -      1.880k in   5.621210s
