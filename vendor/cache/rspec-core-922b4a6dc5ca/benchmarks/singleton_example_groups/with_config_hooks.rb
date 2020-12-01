require_relative "helper"

RSpec.configure do |c|
  10.times do
    c.before(:context, :apply_it) { }
    c.after(:context,  :apply_it) { }
  end
end

BenchmarkHelpers.run_benchmarks

__END__
No match -- without singleton group support
                        575.250  (±29.0%) i/s -      2.484k
No match -- with singleton group support
                        503.671  (±21.8%) i/s -      2.250k
Example match -- without singleton group support
                        544.191  (±25.7%) i/s -      2.160k
Example match -- with singleton group support
                        413.538  (±22.2%) i/s -      1.715k
Group match -- without singleton group support
                        517.998  (±28.2%) i/s -      2.058k
Group match -- with singleton group support
                        431.554  (±15.3%) i/s -      1.960k
Both match -- without singleton group support
                        525.306  (±25.1%) i/s -      2.107k in   5.556760s
Both match -- with singleton group support
                        440.288  (±16.6%) i/s -      1.848k
