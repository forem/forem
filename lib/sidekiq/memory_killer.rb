module Sidekiq
  class MemoryKiller
    DEFAULT_MAX_MB = 950
    DEFAULT_CHECK_INTERVAL_SECONDS = 5
    PROC_STATUS_PATH = "/proc/self/status".freeze

    # Cross-thread state so only one thread checks `/proc/self/status` per interval
    # and SIGTERM is sent at most once per Sidekiq process.
    @mutex = Mutex.new
    @terminating = false
    @last_checked_at = 0.0

    class << self
      attr_accessor :terminating, :last_checked_at
      attr_reader :mutex

      def reset_state!
        @mutex.synchronize do
          @terminating = false
          @last_checked_at = 0.0
        end
      end
    end

    def initialize
      max_rss_env = ENV.fetch("SIDEKIQ_MEMORY_KILLER_MAX_MB", DEFAULT_MAX_MB.to_s).to_s
      @max_rss_mb = max_rss_env.to_i.positive? ? max_rss_env.to_i : DEFAULT_MAX_MB

      interval_env = ENV.fetch("SIDEKIQ_MEMORY_KILLER_CHECK_INTERVAL", DEFAULT_CHECK_INTERVAL_SECONDS.to_s).to_s
      @check_interval = interval_env.to_i >= 0 ? interval_env.to_i : DEFAULT_CHECK_INTERVAL_SECONDS

      @enabled = ENV["SIDEKIQ_MEMORY_KILLER_ENABLED"] == "true"
      @terminating = false
    end

    def call(_worker, _job, _queue)
      yield
    ensure
      check_and_kill! if @enabled && !terminating?
    end

    private

    def terminating?
      @terminating || self.class.terminating
    end

    def should_check_now?
      return false if terminating?
      return true if @check_interval <= 0

      now = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
      return false if (now - self.class.last_checked_at) < @check_interval

      self.class.mutex.synchronize do
        return false if terminating? || (now - self.class.last_checked_at) < @check_interval

        self.class.last_checked_at = now
        true
      end
    end

    def check_and_kill!
      return unless should_check_now?

      rss_kb = extract_memory_kb
      return if rss_kb <= 0

      max_rss_kb = @max_rss_mb * 1024
      return if rss_kb <= max_rss_kb

      should_signal = false
      self.class.mutex.synchronize do
        unless terminating?
          @terminating = true
          self.class.terminating = true
          should_signal = true
        end
      end
      return unless should_signal

      rss_mb = (rss_kb / 1024.0).round(2)
      ::Rails.logger.warn(
        "SidekiqMemoryKiller: Memory usage #{rss_mb}MB (RSS + Swap) exceeds max #{@max_rss_mb}MB. " \
        "Sending SIGTERM to PID #{::Process.pid}.",
      )
      # Send SIGTERM to the current process to gracefully shut down Sidekiq.
      # It will stop accepting new jobs, finish current ones, and then exit.
      ::Process.kill("TERM", ::Process.pid)
    rescue StandardError => e
      ::Rails.logger.error("SidekiqMemoryKiller: Failed to check memory: #{e.message}")
    end

    def extract_memory_kb
      if ::File.exist?(PROC_STATUS_PATH)
        status = ::File.read(PROC_STATUS_PATH)
        total_kb = parse_proc_status_kb(status)
        return total_kb if total_kb.positive?
      end

      `ps -o rss= -p #{::Process.pid}`.strip.to_i
    rescue StandardError => e
      ::Rails.logger.error("SidekiqMemoryKiller: Error checking memory in extract_memory_kb: #{e.message}")
      0
    end

    # Sums VmRSS (physical RAM) + VmSwap (paged-out swap) from `/proc/self/status`.
    # On 1GB Heroku Standard-2X containers, the Linux cgroup caps physical VmRSS near ~960MB
    # and pushes excess memory into VmSwap, so summing both is required to detect when total
    # container memory exceeds 1GB.
    def parse_proc_status_kb(status)
      rss_kb = 0
      swap_kb = 0
      found_rss = false
      found_swap = false

      status.each_line do |line|
        if line.start_with?("VmRSS:")
          rss_kb = line.split[1].to_i
          found_rss = true
        elsif line.start_with?("VmSwap:")
          swap_kb = line.split[1].to_i
          found_swap = true
        end
        break if found_rss && found_swap
      end

      rss_kb + swap_kb
    end
  end
end
