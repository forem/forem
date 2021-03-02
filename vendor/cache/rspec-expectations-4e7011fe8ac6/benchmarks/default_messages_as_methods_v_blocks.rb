require 'benchmark'
require 'rspec/expectations'

include RSpec::Expectations
include RSpec::Matchers

RSpec::Matchers.define :eq_using_dsl do |expected|
  match do |actual|
    actual == expected
  end
end

n = 10_000

Benchmark.benchmark do |bm|
  3.times do
    bm.report do
      n.times do
        eq_using_dsl(5).tap do |m|
          m.description
          m.failure_message_for_should
          m.failure_message_for_should_not
        end
      end
    end
  end
end
