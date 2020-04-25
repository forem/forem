require "rails_helper"

RSpec.describe ActiveSupport::Cache::RedisStore do
  describe "ActiveSupport::Cache::RedisCacheStore" do
    let(:redis_url) { "redis://localhost:6379" }
    let(:redis_client) { Redis.new(url: redis_url) }
    let(:cache_db) { described_class.new(redis_url) }
    let(:key) { "monkey_patch_test" }

    def value
      cache_db.read(key, raw: true).to_i
    end

    def pttl
      redis_client.pttl(key)
    end

    describe ".increment" do
      before do
        cache_db.delete(key)
      end

      it "increments value without expires_in" do
        cache_db.increment(key)

        expect(value).to eq(1)
        expect(pttl).to eq(-1)

        cache_db.increment(key)

        expect(value).to eq(2)
        expect(pttl).to eq(-1)
      end

      it "increments value with expires_in" do
        cache_db.increment(key, 1, expires_in: 100.seconds)
        first_pttl = pttl

        expect(value).to eq(1)
        expect(first_pttl > 0).to be_truthy
        expect(first_pttl < 100_000).to be_truthy

        cache_db.increment(key, 1, expires_in: 100.seconds)
        second_pttl = pttl

        expect(value).to eq(2)
        expect(second_pttl < first_pttl).to be_truthy
      end
    end
  end
end
