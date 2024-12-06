module Benchmark
  module IPS
    # Benchmark jobs.
    class Job
      # Microseconds per 100 millisecond.
      MICROSECONDS_PER_100MS = 100_000
      # Microseconds per second.
      MICROSECONDS_PER_SECOND = Timing::MICROSECONDS_PER_SECOND
      # The percentage of the expected runtime to allow
      # before reporting a weird runtime
      MAX_TIME_SKEW = 0.05
      POW_2_30 = 1 << 30

      # Two-element arrays, consisting of label and block pairs.
      # @return [Array<Entry>] list of entries
      attr_reader :list

      # Determining whether to run comparison utility.
      # @return [Boolean] true if needs to run compare.
      attr_reader :compare

      # Determining whether to hold results between Ruby invocations
      # @return [Boolean]
      attr_accessor :hold

      # Report object containing information about the run.
      # @return [Report] the report object.
      attr_reader :full_report

      # Storing Iterations in time period.
      # @return [Hash]
      attr_reader :timing

      # Warmup time setter and getter (in seconds).
      # @return [Integer]
      attr_accessor :warmup

      # Calculation time setter and getter (in seconds).
      # @return [Integer]
      attr_accessor :time

      # Warmup and calculation iterations.
      # @return [Integer]
      attr_accessor :iterations

      # Statistics model.
      # @return [Object]
      attr_accessor :stats

      # Confidence.
      # @return [Integer]
      attr_accessor :confidence

      # Silence output
      # @return [Boolean]
      attr_reader :quiet

      # Suite
      # @return [Benchmark::IPS::NoopSuite]
      attr_reader :suite

      # Instantiate the Benchmark::IPS::Job.
      def initialize opts={}
        @list = []
        @run_single = false
        @json_path = false
        @compare = false
        @compare_order = :fastest
        @held_path = nil
        @held_results = nil

        @timing = Hash.new 1 # default to 1 in case warmup isn't run
        @full_report = Report.new

        # Default warmup and calculation time in seconds.
        @warmup = 2
        @time = 5
        @iterations = 1

        # Default statistical model
        @stats = :sd
        @confidence = 95

        self.quiet = false
      end

      # Job configuration options, set +@warmup+ and +@time+.
      # @option opts [Integer] :warmup Warmup time.
      # @option opts [Integer] :time Calculation time.
      # @option iterations [Integer] :time Warmup and calculation iterations.
      def config opts
        @warmup = opts[:warmup] if opts[:warmup]
        @time = opts[:time] if opts[:time]
        @suite = opts[:suite] if opts[:suite]
        @iterations = opts[:iterations] if opts[:iterations]
        @stats = opts[:stats] if opts[:stats]
        @confidence = opts[:confidence] if opts[:confidence]
        self.quiet = opts[:quiet] if opts.key?(:quiet)
        self.suite = opts[:suite]
      end

      def quiet=(val)
        @stdout = reporter(quiet: val)
      end

      def suite=(suite)
        @suite = suite || Benchmark::IPS::NoopSuite.new
      end

      def reporter(quiet:)
        quiet ? NoopReport.new : StdoutReport.new
      end

      # Return true if job needs to be compared.
      # @return [Boolean] Need to compare?
      def compare?
        @compare
      end

      # Run comparison utility.
      def compare!(order: :fastest)
        @compare = true
        @compare_order = order
      end

      # Return true if results are held while multiple Ruby invocations
      # @return [Boolean] Need to hold results between multiple Ruby invocations?
      def hold?
        !!@held_path
      end

      # Hold after each iteration.
      # @param held_path [String] File name to store hold file.
      def hold!(held_path)
        @held_path = held_path
        @run_single = true
      end

      # Save interim results. Similar to hold, but all reports are run
      # The report label must change for each invocation.
      # One way to achieve this is to include the version in the label.
      # @param held_path [String] File name to store hold file.
      def save!(held_path)
        @held_path = held_path
        @run_single = false
      end

      # Return true if items are to be run one at a time.
      # For the traditional hold, this is true
      # @return [Boolean] Run just a single item?
      def run_single?
        @run_single
      end

      # Return true if job needs to generate json.
      # @return [Boolean] Need to generate json?
      def json?
        !!@json_path
      end

      # Generate json to given path, defaults to "data.json".
      def json!(path="data.json")
        @json_path = path
      end

      # Registers the given label and block pair in the job list.
      # @param label [String] Label of benchmarked code.
      # @param str [String] Code to be benchmarked.
      # @param blk [Proc] Code to be benchmarked.
      # @raise [ArgumentError] Raises if str and blk are both present.
      # @raise [ArgumentError] Raises if str and blk are both absent.
      def item(label="", str=nil, &blk) # :yield:
        if blk and str
          raise ArgumentError, "specify a block and a str, but not both"
        end

        action = str || blk
        raise ArgumentError, "no block or string" unless action

        @list.push Entry.new(label, action)
        self
      end
      alias_method :report, :item

      # Calculate the cycles needed to run for approx 100ms,
      # given the number of iterations to run the given time.
      # @param [Float] time_msec Each iteration's time in ms.
      # @param [Integer] iters Iterations.
      # @return [Integer] Cycles per 100ms.
      def cycles_per_100ms time_msec, iters
        cycles = ((MICROSECONDS_PER_100MS / time_msec) * iters).to_i
        cycles <= 0 ? 1 : cycles
      end

      # Calculate the time difference of before and after in microseconds.
      # @param [Time] before time.
      # @param [Time] after time.
      # @return [Float] Time difference of before and after.
      def time_us before, after
        (after.to_f - before.to_f) * MICROSECONDS_PER_SECOND
      end

      # Calculate the interations per second given the number
      # of cycles run and the time in microseconds that elapsed.
      # @param [Integer] cycles Cycles.
      # @param [Integer] time_us Time in microsecond.
      # @return [Float] Iteration per second.
      def iterations_per_sec cycles, time_us
        MICROSECONDS_PER_SECOND * (cycles.to_f / time_us.to_f)
      end

      def load_held_results
        return unless @held_path && File.exist?(@held_path) && !File.zero?(@held_path)
        require "json"
        @held_results = {}
        JSON.load(IO.read(@held_path)).each do |result|
          @held_results[result['item']] = result
          create_report(result['item'], result['measured_us'], result['iter'],
                        create_stats(result['samples']), result['cycles'])
        end
      end

      def save_held_results
        return unless @held_path
        require "json"
        data = full_report.entries.map { |e|
          {
            'item' => e.label,
            'measured_us' => e.microseconds,
            'iter' => e.iterations,
            'samples' => e.samples,
            'cycles' => e.measurement_cycle
          }
        }
        IO.write(@held_path, JSON.generate(data) << "\n")
      end

      def all_results_have_been_run?
        @full_report.entries.size == @list.size
      end

      def clear_held_results
        File.delete @held_path if File.exist?(@held_path)
      end

      def run
        if @warmup && @warmup != 0 then
          @stdout.start_warming
          @iterations.times do
            run_warmup
          end
        end

        @stdout.start_running

        @iterations.times do |n|
          run_benchmark
        end

        @stdout.footer
      end

      # Run warmup.
      def run_warmup
        @list.each do |item|
          next if run_single? && @held_results && @held_results.key?(item.label)

          @suite.warming item.label, @warmup
          @stdout.warming item.label, @warmup

          Timing.clean_env

          # Run for up to half of the configured warmup time with an increasing
          # number of cycles to reduce overhead and improve accuracy.
          # This also avoids running with a constant number of cycles, which a
          # JIT might speculate on and then have to recompile in #run_benchmark.
          before = Timing.now
          target = Timing.add_second before, @warmup / 2.0

          cycles = 1
          begin
            t0 = Timing.now
            item.call_times cycles
            t1 = Timing.now
            warmup_iter = cycles
            warmup_time_us = Timing.time_us(t0, t1)

            # If the number of cycles would go outside the 32-bit signed integers range
            # then exit the loop to avoid overflows and start the 100ms warmup runs
            break if cycles >= POW_2_30
            cycles *= 2
          end while Timing.now + warmup_time_us * 2 < target

          cycles = cycles_per_100ms warmup_time_us, warmup_iter
          @timing[item] = cycles

          # Run for the remaining of warmup in a similar way as #run_benchmark.
          target = Timing.add_second before, @warmup
          while Timing.now + MICROSECONDS_PER_100MS < target
            item.call_times cycles
          end

          @stdout.warmup_stats warmup_time_us, @timing[item]
          @suite.warmup_stats warmup_time_us, @timing[item]

          break if run_single?
        end
      end

      # Run calculation.
      def run_benchmark
        @list.each do |item|
          next if run_single? && @held_results && @held_results.key?(item.label)

          @suite.running item.label, @time
          @stdout.running item.label, @time

          Timing.clean_env

          iter = 0

          measurements_us = []

          # Running this number of cycles should take around 100ms.
          cycles = @timing[item]

          target = Timing.add_second Timing.now, @time

          begin
            before = Timing.now
            item.call_times cycles
            after = Timing.now

            # If for some reason the timing said this took no time (O_o)
            # then ignore the iteration entirely and start another.
            iter_us = Timing.time_us before, after
            next if iter_us <= 0.0

            iter += cycles

            measurements_us << iter_us
          end while Timing.now < target

          final_time = before

          measured_us = measurements_us.inject(:+)

          samples = measurements_us.map { |time_us|
            iterations_per_sec cycles, time_us
          }

          rep = create_report(item.label, measured_us, iter, create_stats(samples), cycles)

          if (final_time - target).abs >= (@time.to_f * MAX_TIME_SKEW)
            rep.show_total_time!
          end

          @stdout.add_report rep, caller(1).first
          @suite.add_report rep, caller(1).first

          break if run_single?
        end
      end

      def create_stats(samples)
        case @stats
          when :sd
            Stats::SD.new(samples)
          when :bootstrap
            Stats::Bootstrap.new(samples, @confidence)
          else
            raise "unknown stats #{@stats}"
        end
      end

      # Run comparison of entries in +@full_report+.
      def run_comparison
        @full_report.run_comparison(@compare_order) if compare?
      end

      # Generate json from +@full_report+.
      def generate_json
        @full_report.generate_json @json_path if json?
      end

      # Create report by add entry to +@full_report+.
      # @param label [String] Report item label.
      # @param measured_us [Integer] Measured time in microsecond.
      # @param iter [Integer] Iterations.
      # @param samples [Array<Float>] Sampled iterations per second.
      # @param cycles [Integer] Number of Cycles.
      # @return [Report::Entry] Entry with data.
      def create_report(label, measured_us, iter, samples, cycles)
        @full_report.add_entry label, measured_us, iter, samples, cycles
      end
    end
  end
end
