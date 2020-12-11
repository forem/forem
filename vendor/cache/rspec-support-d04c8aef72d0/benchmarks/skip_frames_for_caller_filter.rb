require 'rspec/support/caller_filter'

eval <<-EOS, binding, "/lib/rspec/core/some_file.rb", 1 # make it think this code is in rspec-core
  class Recurser
    def self.recurse(times, *args)
      return RSpec::CallerFilter.first_non_rspec_line(*args) if times.zero?
      recurse(times - 1, *args)
    end
  end
EOS

# Ensure the correct first_non_rspec_line is found in these cases.
puts Recurser.recurse(20, 19)
puts Recurser.recurse(20)

require 'benchmark/ips'

Benchmark.ips do |x|
  x.report("(no args)") { Recurser.recurse(20)        }
  x.report("(19)")      { Recurser.recurse(20, 19)    }
  x.report("(19, 2)")   { Recurser.recurse(20, 19, 2) }
end

__END__
 (no args)     13.789k (± 7.8%) i/s -     69.377k
      (19)     55.410k (± 8.4%) i/s -    275.123k
   (19, 2)     61.076k (± 8.6%) i/s -    303.637k
