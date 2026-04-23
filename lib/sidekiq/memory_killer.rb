# frozen_string_literal: true

module Sidekiq
  class MemoryKiller
    def initialize
      max_rss_env = ENV.fetch("SIDEKIQ_MEMORY_KILLER_MAX_MB", "1024").to_s
      @max_rss_mb = max_rss_env.to_i > 0 ? max_rss_env.to_i : 1024
      @enabled = ENV["SIDEKIQ_MEMORY_KILLER_ENABLED"] == "true"
      @terminating = false
    end

    def call(worker, job, queue)
      yield
    ensure
      check_and_kill! if @enabled && !@terminating
    end

    private

    def check_and_kill!
      rss_kb = extract_memory_kb
      return if rss_kb <= 0

      rss_mb = rss_kb / 1024

      if rss_mb > @max_rss_mb
        @terminating = true
        ::Rails.logger.warn("SidekiqMemoryKiller: Memory usage #{rss_mb}MB exceeds max #{@max_rss_mb}MB. Sending SIGTERM to PID #{::Process.pid}.")
        # Send SIGTERM to the current process to gracefully shut down Sidekiq.
        # It will stop accepting new jobs, finish current ones, and then exit.
        ::Process.kill("TERM", ::Process.pid)
      end
    rescue StandardError => e
      ::Rails.logger.error("SidekiqMemoryKiller: Failed to check memory: #{e.message}")
    end

    def extract_memory_kb
      if File.exist?("/proc/self/status")
        status = ::File.read("/proc/self/status")
        rss_line = status.each_line.find { |line| line.start_with?("VmRSS:") }
        return rss_line.split[1].to_i if rss_line
      end
      
      `ps -o rss= -p #{::Process.pid}`.strip.to_i
    rescue StandardError
      0
    end
  end
end
