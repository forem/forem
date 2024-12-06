# frozen_string_literal: true

require 'bigdecimal'
require 'statistics'
require 'stringio'
require 'mini_histogram'
require 'mini_histogram/plot'

module DerailedBenchmarks
  # A class used to read several benchmark files
  # it will parse each file, then sort by average
  # time of benchmarks. It can be used to find
  # the fastest and slowest examples and give information
  # about them such as what the percent difference is
  # and if the results are statistically significant
  #
  # Example:
  #
  #   branch_info = {}
  #   branch_info["loser"]  = { desc: "Old commit", time: Time.now, file: dir.join("loser.bench.txt"), name: "loser" }
  #   branch_info["winner"] = { desc: "I am the new commit", time: Time.now + 1, file: dir.join("winner.bench.txt"), name: "winner" }
  #   stats = DerailedBenchmarks::StatsFromDir.new(branch_info)
  #
  #   stats.newest.average  # => 10.5
  #   stats.oldest.average  # => 11.0
  #   stats.significant?    # => true
  #   stats.x_faster        # => "1.0476"
  class StatsFromDir
    FORMAT = "%0.4f"
    attr_reader :stats, :oldest, :newest

    def initialize(input)
      @files = []

      if input.is_a?(Hash)
        hash = input
        hash.each do |branch, info_hash|
          file = info_hash.fetch(:file)
          desc = info_hash.fetch(:desc)
          time = info_hash.fetch(:time)
          short_sha = info_hash[:short_sha]
          @files << StatsForFile.new(file: file, desc: desc, time: time, name: branch, short_sha: short_sha)
        end
      else
        input.each do |commit|
          @files << StatsForFile.new(
            file: commit.file,
            desc: commit.desc,
            time: commit.time,
            name: commit.ref,
            short_sha: commit.short_sha
          )
        end
      end
      @files.sort_by! { |f| f.time }
      @oldest = @files.first
      @newest = @files.last
    end

    def call
      @files.each(&:call)

      return self if @files.detect(&:empty?)

      stats_95 = statistical_test(confidence: 95)

      # If default check is good, see if we also pass a more rigorous test
      # if so, then use the more rigourous test
      if stats_95[:alternative]
        stats_99 = statistical_test(confidence: 99)
        @stats = stats_99 if stats_99[:alternative]
      end
      @stats ||= stats_95

      self
    end

    def statistical_test(series_1=oldest.values, series_2=newest.values, confidence: 95)
      StatisticalTest::KSTest.two_samples(
        group_one: series_1,
        group_two: series_2,
        alpha: (100 - confidence) / 100.0
      )
    end

    def significant?
      @stats[:alternative]
    end

    def d_max
      @stats[:d_max].to_f
    end

    def d_critical
      @stats[:d_critical].to_f
    end

    def x_faster
      (oldest.median/newest.median).to_f
    end

    def faster?
      newest.median < oldest.median
    end

    def percent_faster
      (((oldest.median - newest.median) / oldest.median).to_f  * 100)
    end

    def change_direction
      if faster?
        "FASTER 🚀🚀🚀"
      else
        "SLOWER 🐢🐢🐢"
      end
    end

    def align
      " " * (percent_faster.to_s.index(".") - x_faster.to_s.index("."))
    end

    def histogram(io = $stdout)
      dual_histogram = MiniHistogram.dual_plot do |a, b|
        a.values = newest.values
        a.options = {
          title: "\n   [#{newest.short_sha || newest.name}] description:\n     #{newest.desc.inspect}",
          xlabel: "# of runs in range"
        }
        b.values = oldest.values
        b.options = {
          title: "\n   [#{oldest.short_sha || oldest.name}] description:\n     #{oldest.desc.inspect}",
          xlabel: "# of runs in range"
        }
      end

      io.puts
      io.puts "Histograms (time ranges are in seconds):"
      io.puts(dual_histogram)
      io.puts
    end

    def banner(io = $stdout)
      return if @files.detect(&:empty?)

      io.puts
      if significant?
        io.puts "❤️ ❤️ ❤️  (Statistically Significant) ❤️ ❤️ ❤️"
      else
        io.puts "👎👎👎(NOT Statistically Significant) 👎👎👎"
      end
      io.puts
      io.puts "[#{newest.short_sha || newest.name}] (#{FORMAT % newest.median} seconds) #{newest.desc.inspect} ref: #{newest.name.inspect}"
      io.puts "  #{change_direction} by:"
      io.puts "    #{align}#{FORMAT % x_faster}x [older/newer]"
      io.puts "    #{FORMAT % percent_faster}\% [(older - newer) / older * 100]"
      io.puts "[#{oldest.short_sha || oldest.name}] (#{FORMAT % oldest.median} seconds) #{oldest.desc.inspect} ref: #{oldest.name.inspect}"
      io.puts
      io.puts "Iterations per sample: #{ENV["TEST_COUNT"]}"
      io.puts "Samples: #{newest.values.length}"
      io.puts
      io.puts "Test type: Kolmogorov Smirnov"
      io.puts "Confidence level: #{@stats[:confidence_level] * 100} %"
      io.puts "Is significant? (max > critical): #{significant?}"
      io.puts "D critical: #{d_critical}"
      io.puts "D max: #{d_max}"

      histogram(io)

      io.puts
    end
  end
end
