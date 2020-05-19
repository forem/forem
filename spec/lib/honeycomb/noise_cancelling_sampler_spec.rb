require "rails_helper"

RSpec.describe Honeycomb::NoiseCancellingSampler do
  let(:trace_id) { "TRACE_ID" }

  before { allow(described_class).to receive(:should_sample) }

  context "without a noisy command" do
    it "does not sample" do
      result = described_class.sample({ "request.path" => "/me", "trace.trace_id" => trace_id })
      expect(described_class).not_to have_received(:should_sample)
      expect(result).to eq([true, 1])
    end
  end

  context "with a redis command" do
    it "samples if its a NOISY_COMMANDS" do
      described_class.sample({ "redis.command" => "TIME", "trace.trace_id" => trace_id })
      expect(described_class).to have_received(:should_sample).with(100, trace_id)
    end

    it "samples if the command is BRPOP" do
      described_class.sample({ "redis.command" => "BRPOP", "trace.trace_id" => trace_id })
      expect(described_class).to have_received(:should_sample).with(1000, trace_id)
    end

    it "samples if the command starts with TTL" do
      described_class.sample({ "redis.command" => "TTL this and that", "trace.trace_id" => trace_id })
      expect(described_class).to have_received(:should_sample).with(100, trace_id)
    end
  end

  context "with a active_record SQL command" do
    it "samples if its a NOISY_COMMANDS" do
      described_class.sample({ "sql.active_record.sql" => "COMMIT", "trace.trace_id" => trace_id })
      expect(described_class).to have_received(:should_sample).with(100, trace_id)
    end
  end
end
