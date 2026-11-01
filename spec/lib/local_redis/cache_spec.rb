require "spec_helper"
require_relative "../../../lib/local_redis/cache"

RSpec.describe LocalRedis::Cache do
  describe ".max_ttl_ms" do
    it "defaults to 30 seconds when unset" do
      stub_const("ENV", ENV.to_h.except("LOCAL_REDIS_MAX_TTL"))
      expect(described_class.max_ttl_ms).to eq(30_000)
    end

    [1, 30, 120, 300, 600].each do |seconds|
      it "accepts #{seconds} seconds" do
        stub_const("ENV", ENV.to_h.merge("LOCAL_REDIS_MAX_TTL" => seconds.to_s))
        expect(described_class.max_ttl_ms).to eq(seconds * 1000)
      end
    end

    ["", "0", "-1", "601", "10000000000", "30s", "30.5", "Infinity", " 30", "1e2"].each do |value|
      it "rejects #{value.inspect} without allowing an unbounded lifetime" do
        stub_const("ENV", ENV.to_h.merge("LOCAL_REDIS_MAX_TTL" => value))
        expect { described_class.max_ttl_ms }.to raise_error(ArgumentError, /whole seconds between 1 and 600/)
      end
    end
  end
end
