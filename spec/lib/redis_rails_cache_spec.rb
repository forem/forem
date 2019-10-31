require "rails_helper"

RSpec.describe RedisRailsCache do
  let(:redis_client) { class_double("RedisClient") }

  before do
    allow(described_class).to receive(:client) { redis_client }
    allow(redis_client).to receive(:set).and_return("OK")
    allow(redis_client).to receive(:get)
  end

  describe "#fetch" do
    context "when block is present" do
      it "returns key value if present" do
        allow(redis_client).to receive(:get).with("five").and_return(5)
        result = described_class.fetch("five") do
          5
        end
        expect(redis_client).to have_received(:get).with("five")
        expect(result).to eq(5)
      end

      it "when key is missing sets key value to result of the block and expiration" do
        result = described_class.fetch("five") do
          5
        end
        expect(redis_client).to have_received(:get).with("five")
        expect(redis_client).to have_received(:set).with(
          "five", 5, ex: described_class::DEFAULT_EXPIRATION
        )
        expect(result).to eq(5)
      end

      it "when key is missing sets key value and custom expiration" do
        result = described_class.fetch("five", expires_in: 100) do
          5
        end
        expect(redis_client).to have_received(:get).with("five")
        expect(redis_client).to have_received(:set).with("five", 5, ex: 100)
        expect(result).to eq(5)
      end
    end

    context "without block present" do
      it "returns the value of the key from the cache" do
        allow(redis_client).to receive(:get).with("five").and_return(5)
        result = described_class.fetch("five")
        expect(redis_client).to have_received(:get).with("five")
        expect(result).to eq(5)
      end
    end
  end

  describe "#read" do
    it "gets the key from RedisClient" do
      described_class.read("foo")
      expect(redis_client).to have_received(:get).with("foo")
    end
  end

  describe "#write" do
    it "sets the key in RedisClient with default expiration" do
      described_class.write("foo", 2)
      expect(redis_client).to have_received(:set).with(
        "foo", 2, ex: described_class::DEFAULT_EXPIRATION
      )
    end

    it "sets the key in RedisClient with custom expiration" do
      described_class.write("foo", 2, expires_in: 100)
      expect(redis_client).to have_received(:set).with(
        "foo", 2, ex: 100
      )
    end
  end
end
