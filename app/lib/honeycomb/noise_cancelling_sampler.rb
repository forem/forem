module Honeycomb
  class NoiseCancellingSampler
    extend Honeycomb::DeterministicSampler

    NOISY_REDIS_COMMANDS = [
      "GET rails-settings-cached/v1",
      "TIME",
    ].freeze

    NOISY_SQL_COMMANDS = %w[
      BEGIN
      COMMIT
    ].freeze

    NOISY_REDIS_PREFIXES = [
      "INCRBY",
      "TTL",
      "GET rack:",
      "SET rack:",
      "GET views/shell",
    ].freeze

    def self.sample(fields)
      rate = 1 # include everything by default
      # should_sample is a no-op if the rate is 1

      if fields["redis.command"].in? NOISY_REDIS_COMMANDS
        rate = 300
      elsif fields["sql.active_record.sql"].in? NOISY_SQL_COMMANDS
        rate = 300
      elsif fields["redis.command"]&.start_with?("BRPOP")
        # BRPOP is disproportionately noisy and not really interesting
        rate = 5000
      elsif fields["redis.command"]&.start_with?(*NOISY_REDIS_PREFIXES)
        rate = 300
      end
      [should_sample(rate, fields["trace.trace_id"]), rate]
    end
  end
end
