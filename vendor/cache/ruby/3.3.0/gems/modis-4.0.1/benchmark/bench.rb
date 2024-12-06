# frozen_string_literal: true

require 'stackprof'
require 'benchmark'

$LOAD_PATH.unshift('.')
require 'lib/modis'

puts "Profiler enabled." if ENV['PROFILE']

Modis.configure do |config|
  config.namespace = 'modis_benchmark'
end

class Bench
  def self.run
    bench = new
    yield(bench)
    bench._run
  end

  def initialize
    @bms = []
    @profiles = []
  end

  def report(name, &blk)
    @bms << [name, blk]
  end

  def _run
    Benchmark.bmbm do |x|
      @bms.each do |name, blk|
        x.report(name) do
          with_profile(name, &blk)
        end
      end
    end

    after
  end

  private

  def with_profile(name)
    if ENV['PROFILE']
      mode = :wall
      out = "tmp/stackprof-#{mode}-#{name}.dump"
      @profiles << out
      StackProf.run(mode: mode, out: out, &Proc.new)
    else
      yield
    end
  end

  def after
    Modis.with_connection do |connection|
      keys = connection.keys "#{Modis.config.namespace}:*"
      connection.del(*keys) unless keys.empty?
    end

    return unless @profiles.any?

    puts "\nProfiler dumps:"
    @profiles.uniq.each { |dump| puts " * stackprof #{dump} --text" }
  end
end
