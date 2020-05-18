module Honeycomb
  class NoiseCancellingSampler
    extend Honeycomb::DeterministicSampler

    NOISY_COMMANDS = [
      "GET rails-settings-cached/v1",
      "TIME",
      "BEGIN",
      "COMMIT",
    ].freeze

    NOISY_PREFIXES = [
      "INCRBY",
      "TTL",
      "GET rack:",
      "SET rack:",
      "GET views/shell",
    ].freeze

    def self.sample(fields)
      if (NOISY_COMMANDS & [fields["redis.command"], fields["sql.active_record.sql"]]).any?
        rate = 100
        [should_sample(rate, fields["trace.trace_id"]), rate]
      elsif fields["redis.command"]&.start_with?("BRPOP")
        rate = 1000
        [should_sample(rate, fields["trace.trace_id"]), rate]
      elsif fields["redis.command"]&.start_with?(*NOISY_PREFIXES)
        rate = 100
        [should_sample(rate, fields["trace.trace_id"]), rate]
      else
        [true, 1]
      end
    end
  end
end
