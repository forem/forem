require 'benchmark'
require_relative '../lib/smart_properties'

class A
  include SmartProperties
  property :a
end

class B < A
  property :b
end

class C < B
  property :c
end

class A2
  def initialize(**attrs)
    attrs.each { |k, v| send("#{k}=", v) }
  end
  attr_accessor :a
end

class B2 < A2
  attr_accessor :b
end

class C2 < B2
  attr_accessor :c
end

puts Benchmark.measure { 1_000_000.times { C.new(a: 1, b: 2, c: 3) } }
# puts Benchmark.measure { 1_000_000.times { C2.new(a: 1, b: 2, c: 3) } }

