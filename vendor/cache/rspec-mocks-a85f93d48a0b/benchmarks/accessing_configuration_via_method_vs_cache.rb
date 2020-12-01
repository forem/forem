require 'benchmark'

n = 10_000

require 'rspec/mocks'

# precache config
RSpec::Mocks.configuration

Benchmark.benchmark do |bm|
  puts "#{n} times - ruby #{RUBY_VERSION}"

  puts
  puts "directly"

  3.times do
    bm.report do
      n.times do
        original_state = RSpec::Mocks.configuration.temporarily_suppress_partial_double_verification
        RSpec::Mocks.configuration.temporarily_suppress_partial_double_verification = true
        RSpec::Mocks.configuration.temporarily_suppress_partial_double_verification = original_state
      end
    end
  end

  puts
  puts "with cached value"

  3.times do
    bm.report do
      n.times do
        config = RSpec::Mocks.configuration
        original_state = config.temporarily_suppress_partial_double_verification
        config.temporarily_suppress_partial_double_verification = true
        config.temporarily_suppress_partial_double_verification = original_state
      end
    end
  end
end

__END__
10000 times - ruby 2.3.1

directly
   0.000000   0.000000   0.000000 (  0.002654)
   0.000000   0.000000   0.000000 (  0.002647)
   0.010000   0.000000   0.010000 (  0.002645)

with cached value
   0.000000   0.000000   0.000000 (  0.001386)
   0.000000   0.000000   0.000000 (  0.001387)
   0.000000   0.000000   0.000000 (  0.001399)
