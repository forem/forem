# frozen_string_literal: true

module Sidekiq
  class MemoryKiller
    def initialize
      @max_rss_mb = ENV.fetch("SIDEKIQ_MEMORY_KILLER_MAX_MB", 1024).to_i
      @enabled = ENV["SIDEKIQ_MEMORY_KILLER_ENABLED"] == "true"
    end

    def call(worker, job, queue)
      yield
    ensure
      check_and_kill! if @enabled
    end

    private

    def check_and_kill!
      rss_kb = extract_memory_kb
      rss_mb = rss_kb / 1024

      if rss_mb > @max_rss_mb
        ::Rails.logger.warn("SidekiqMemoryKiller: Memory usage #{rss_mb}MB exceeds max #{@max_rss_mb}MB. Sending SIGTERM to PID #{::Process.pid}.")
        # Send SIGTERM to the current process to gracefully shut down Sidekiq.
        # It will stop accepting new jobs, finish current ones, and then exit.
        ::Process.kill("TERM", ::Process.pid)
      end
    rescue StandardError => e
      ::Rails.logger.error("SidekiqMemoryKiller: Failed to check memory: #{e.message}")
    end

    def extract_memory_kb
      `ps -o rss= -p #{::Process.pid}`.strip.to_i
    end
  end
end
