require_relative "helper"

RSpec.configure do |c|
  10.times do
    c.before(:context, :apply_it) { }
    c.after(:context,  :apply_it) { }
    c.include Module.new, :apply_it
  end
end

1.upto(10) do |i|
  RSpec.shared_context "context #{i}", :apply_it do
  end
end

BenchmarkHelpers.run_benchmarks

__END__

No match -- without singleton group support
                        544.396  (±34.0%) i/s -      2.340k
No match -- with singleton group support
                        451.635  (±31.0%) i/s -      1.935k
Example match -- without singleton group support
                        538.788  (±23.8%) i/s -      2.450k
Example match -- with singleton group support
                        342.990  (±22.4%) i/s -      1.440k
Group match -- without singleton group support
                        509.969  (±26.7%) i/s -      2.070k
Group match -- with singleton group support
                        405.284  (±20.5%) i/s -      1.518k
Both match -- without singleton group support
                        513.344  (±24.0%) i/s -      1.927k
Both match -- with singleton group support
                        406.111  (±18.5%) i/s -      1.760k
