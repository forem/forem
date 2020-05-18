module Honeycomb
  class NoiseCancellingSampler
    extend Honeycomb::DeterministicSampler

    NOISY_COMMANDS = [
      "GET rails-settings-cached/v1",
      "TIME",
      "BEGIN",
      "COMMIT",
      "GET rack:",
      "SET rack:",
      "GET views/shell",
    ].freeze

    def self.sample(fields)
      if NOISY_COMMANDS.include?(fields["redis.command"]) || NOISY_COMMANDS.include?(fields["sql.active_record.sql"])
        rate = 100
        [should_sample(rate, fields["trace.trace_id"]), rate]
      elsif fields["redis.command"]&.start_with?("BRPOP")
        rate = 1000
        [should_sample(rate, fields["trace.trace_id"]), rate]
      elsif fields["redis.command"]&.start_with?("INCRBY") || fields["redis.command"]&.start_with?("TTL")
        rate = 100
        [should_sample(rate, fields["trace.trace_id"]), rate]
      else
        [true, 1]
      end
    end
  end
end
