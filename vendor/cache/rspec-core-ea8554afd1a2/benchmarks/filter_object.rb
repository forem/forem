require 'benchmark'
require 'tmpdir'

path = File.join(Dir.tmpdir, "benchmark_example_spec.rb")

File.open(path, 'w') do |f|
  f.puts %q|describe "something" do|
  100.times do |n|
    f.puts <<-TEXT
  it "does something #{n}", :focus => true do
  end
TEXT
  end
  100.times do |n|
    f.puts <<-TEXT
  it "does something else #{n}" do
  end
TEXT
  end
  f.puts %q|end|
end

n = 1

Benchmark.benchmark do |bm|
  3.times do
    bm.report do
      n.times do
        `bin/rspec --tag focus #{path}`
      end
    end
  end
end

File.delete(path)
