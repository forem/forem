module Benchmark
  # Perform caclulations on Timing results.
  module Timing
    # Microseconds per second.
    MICROSECONDS_PER_SECOND = 1_000_000

    # Calculate (arithmetic) mean of given samples.
    # @param [Array] samples Samples to calculate mean.
    # @return [Float] Mean of given samples.
    def self.mean(samples)
      sum = samples.inject(:+)
      sum / samples.size
    end

    # Calculate variance of given samples.
    # @param [Float] m Optional mean (Expected value).
    # @return [Float] Variance of given samples.
    def self.variance(samples, m=nil)
      m ||= mean(samples)

      total = samples.inject(0) { |acc, i| acc + ((i - m) ** 2) }

      total / samples.size
    end

    # Calculate standard deviation of given samples.
    # @param [Array] samples Samples to calculate standard deviation.
    # @param [Float] m Optional mean (Expected value).
    # @return [Float] standard deviation of given samples.
    def self.stddev(samples, m=nil)
      Math.sqrt variance(samples, m)
    end

    # Recycle used objects by starting Garbage Collector.
    def self.clean_env
      # rbx
      if GC.respond_to? :run
        GC.run(true)
      else
        GC.start
      end
    end

    # Use a monotonic clock if available, otherwise use Time
    begin
      Process.clock_gettime Process::CLOCK_MONOTONIC, :float_microsecond

      # Get an object that represents now and can be converted to microseconds
      def self.now
        Process.clock_gettime Process::CLOCK_MONOTONIC, :float_microsecond
      end

      # Add one second to the time represenetation
      def self.add_second(t, s)
        t + (s * MICROSECONDS_PER_SECOND)
      end

      # Return the number of microseconds between the 2 moments
      def self.time_us(before, after)
        after - before
      end
    rescue NameError
      # Get an object that represents now and can be converted to microseconds
      def self.now
        Time.now
      end

      # Add one second to the time represenetation
      def self.add_second(t, s)
        t + s
      end

      # Return the number of microseconds between the 2 moments
      def self.time_us(before, after)
        (after.to_f - before.to_f) * MICROSECONDS_PER_SECOND
      end
    end
  end
end
