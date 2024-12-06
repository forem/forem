# encoding: utf-8
require 'benchmark/timing'
require 'benchmark/compare'
require 'benchmark/ips/stats/stats_metric'
require 'benchmark/ips/stats/sd'
require 'benchmark/ips/stats/bootstrap'
require 'benchmark/ips/report'
require 'benchmark/ips/noop_suite'
require 'benchmark/ips/job/entry'
require 'benchmark/ips/job/stdout_report'
require 'benchmark/ips/job/noop_report'
require 'benchmark/ips/job'

# Performance benchmarking library
module Benchmark
  # Benchmark in iterations per second, no more guessing!
  # @see https://github.com/evanphx/benchmark-ips
  module IPS

    # Benchmark-ips Gem version.
    VERSION = "2.10.0"

    # CODENAME of current version.
    CODENAME = "Watashi Wa Genki"

    # Measure code in block, each code's benchmarked result will display in
    # iteration per second with standard deviation in given time.
    # @param time [Integer] Specify how long should benchmark your code in seconds.
    # @param warmup [Integer] Specify how long should Warmup time run in seconds.
    # @return [Report]
    def ips(*args)
      if args[0].is_a?(Hash)
        time, warmup, quiet = args[0].values_at(:time, :warmup, :quiet)
      else
        time, warmup, quiet = args
      end

      sync, $stdout.sync = $stdout.sync, true

      job = Job.new

      job_opts = {}
      job_opts[:time] = time unless time.nil?
      job_opts[:warmup] = warmup unless warmup.nil?
      job_opts[:quiet] = quiet unless quiet.nil?

      job.config job_opts

      yield job

      job.load_held_results

      job.run

      if job.run_single? && job.all_results_have_been_run?
        job.clear_held_results
      else
        job.save_held_results
        puts '', 'Pausing here -- run Ruby again to measure the next benchmark...' if job.run_single?
      end

      $stdout.sync = sync
      job.run_comparison
      job.generate_json

      report = job.full_report

      if ENV['SHARE'] || ENV['SHARE_URL']
        require 'benchmark/ips/share'
        share = Share.new report, job
        share.share
      end

      report
    end

    # Set options for running the benchmarks.
    # :format => [:human, :raw]
    #    :human format narrows precision and scales results for readability
    #    :raw format displays 6 places of precision and exact iteration counts
    def self.options
      @options ||= {:format => :human}
    end

    module Helpers
      def scale(value)
        scale = (Math.log10(value) / 3).to_i
        suffix = case scale
        when 1; 'k'
        when 2; 'M'
        when 3; 'B'
        when 4; 'T'
        when 5; 'Q'
        else
          # < 1000 or > 10^15, no scale or suffix
          scale = 0
          ' '
        end
        "%10.3f#{suffix}" % (value.to_f / (1000 ** scale))
      end
      module_function :scale
    end
  end

  extend Benchmark::IPS # make ips available as module-level method

  ##
  # :singleton-method: ips
  #
  #     require 'benchmark/ips'
  #
  #     Benchmark.ips do |x|
  #       # Configure the number of seconds used during
  #       # the warmup phase (default 2) and calculation phase (default 5)
  #       x.config(:time => 5, :warmup => 2)
  #
  #       # These parameters can also be configured this way
  #       x.time = 5
  #       x.warmup = 2
  #
  #       # Typical mode, runs the block as many times as it can
  #       x.report("addition") { 1 + 2 }
  #
  #       # To reduce overhead, the number of iterations is passed in
  #       # and the block must run the code the specific number of times.
  #       # Used for when the workload is very small and any overhead
  #       # introduces incorrectable errors.
  #       x.report("addition2") do |times|
  #         i = 0
  #         while i < times
  #           1 + 2
  #           i += 1
  #         end
  #       end
  #
  #       # To reduce overhead even more, grafts the code given into
  #       # the loop that performs the iterations internally to reduce
  #       # overhead. Typically not needed, use the |times| form instead.
  #       x.report("addition3", "1 + 2")
  #
  #       # Really long labels should be formatted correctly
  #       x.report("addition-test-long-label") { 1 + 2 }
  #
  #       # Compare the iterations per second of the various reports!
  #       x.compare!
  #     end
  #
  # This will generate the following report:
  #
  #     Calculating -------------------------------------
  #                 addition    71.254k i/100ms
  #                addition2    68.658k i/100ms
  #                addition3    83.079k i/100ms
  #     addition-test-long-label
  #                             70.129k i/100ms
  #     -------------------------------------------------
  #                 addition     4.955M (± 8.7%) i/s -     24.155M
  #                addition2    24.011M (± 9.5%) i/s -    114.246M
  #                addition3    23.958M (±10.1%) i/s -    115.064M
  #     addition-test-long-label
  #                              5.014M (± 9.1%) i/s -     24.545M
  #
  #     Comparison:
  #                addition2: 24011974.8 i/s
  #                addition3: 23958619.8 i/s - 1.00x slower
  #     addition-test-long-label:  5014756.0 i/s - 4.79x slower
  #                 addition:  4955278.9 i/s - 4.85x slower
  #
  # See also Benchmark::IPS
end
