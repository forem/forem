require 'rubygems'
require 'bundler/setup'
require 'benchmark'
require 'rspec/expectations'
include RSpec::Matchers

n = 100_000

Benchmark.bm(25) do |bm|
  bm.report("to_stdout with StringIO") do
    n.times { expect {}.not_to output('foo').to_stdout }
  end

  bm.report("to_stdout with Tempfile") do
    n.times { expect {}.not_to output('foo').to_stdout_from_any_process }
  end

  bm.report("to_stderr with StringIO") do
    n.times { expect {}.not_to output('foo').to_stderr }
  end

  bm.report("to_stderr with Tempfile") do
    n.times { expect {}.not_to output('foo').to_stderr_from_any_process }
  end
end

#                                 user     system      total        real
# to_stdout with StringIO     0.470000   0.010000   0.480000 (  0.467317)
# to_stdout with Tempfile     8.920000   7.420000  16.340000 ( 16.355174)
# to_stderr with StringIO     0.460000   0.000000   0.460000 (  0.454059)
# to_stderr with Tempfile     8.930000   7.560000  16.490000 ( 16.494696)
