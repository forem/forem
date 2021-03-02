require_relative "helper"

BenchmarkHelpers.run_benchmarks

__END__

No match -- without singleton group support
                        565.198  (±28.8%) i/s -      2.438k
No match -- with singleton group support
                        539.781  (±18.9%) i/s -      2.496k
Example match -- without singleton group support
                        539.287  (±28.2%) i/s -      2.450k in   5.555471s
Example match -- with singleton group support
                        511.576  (±28.1%) i/s -      2.058k
Group match -- without singleton group support
                        535.298  (±23.2%) i/s -      2.352k
Group match -- with singleton group support
                        539.454  (±19.1%) i/s -      2.350k
Both match -- without singleton group support
                        550.932  (±32.1%) i/s -      2.145k in   5.930432s
Both match -- with singleton group support
                        540.183  (±19.6%) i/s -      2.300k
