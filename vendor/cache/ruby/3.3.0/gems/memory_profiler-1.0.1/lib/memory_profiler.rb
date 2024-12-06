# frozen_string_literal: true

require "memory_profiler/version"
require "memory_profiler/helpers"
require "memory_profiler/polychrome"
require "memory_profiler/monochrome"
require "memory_profiler/top_n"
require "memory_profiler/stat"
require "memory_profiler/stat_hash"
require "memory_profiler/results"
require "memory_profiler/reporter"
require "memory_profiler/cli"

module MemoryProfiler
  def self.report(opts = {}, &block)
    Reporter.report(opts, &block)
  end

  def self.start(opts = {})
    unless Reporter.current_reporter
      Reporter.current_reporter = Reporter.new(opts)
      Reporter.current_reporter.start
    end
  end

  def self.stop
    Reporter.current_reporter.stop if Reporter.current_reporter
  ensure
    Reporter.current_reporter = nil
  end
end
