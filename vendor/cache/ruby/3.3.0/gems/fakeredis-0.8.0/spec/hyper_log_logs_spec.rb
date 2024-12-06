require "spec_helper"

module FakeRedis
  describe "HyperLogLogsMethods" do
    let(:redis) { Redis.new }

    it "should add item to hyperloglog" do
      expect(redis.pfadd("hll", "val")).to eq(true)
      expect(redis.pfcount("hll")).to eq(1)
    end

    it "should not add duplicated item to hyperloglog" do
      redis.pfadd("hll", "val")
      expect(redis.pfadd("hll", "val")).to eq(false)
      expect(redis.pfcount("hll")).to eq(1)
    end

    it "should not add multiple items to hyperloglog" do
      expect(redis.pfadd("hll", ["val1", "val2"])).to eq(true)
      expect(redis.pfcount("hll")).to eq(2)
    end

    it "should return zero as cardinality for nonexistent key" do
      expect(redis.pfcount("nonexistent")).to eq(0)
    end

    it "should return cardinality of union of hyperloglogs" do
      redis.pfadd("hll1", ["val1", "val2"])
      redis.pfadd("hll2", ["val2", "val3"])
      expect(redis.pfcount("hll1", "hll2")).to eq(3)
    end

    it "should error if an empty list of keys is given" do
      expect { redis.pfcount([]) }.to raise_error(Redis::CommandError, "ERR wrong number of arguments for 'pfcount' command")
    end

    it "should merge hyperloglogs" do
      redis.pfadd("hll1", ["val1", "val2"])
      redis.pfadd("hll2", ["val2", "val3"])
      expect(redis.pfmerge("hll3", "hll1", "hll2")).to eq(true)
      expect(redis.pfcount("hll3")).to eq(3)
    end

    it "should merge nonexistent hyperloglogs with others" do
      redis.pfadd("hll1", "val")
      expect(redis.pfmerge("hll3", "hll1", "nonexistent")).to eq(true)
      expect(redis.pfcount("hll3")).to eq(1)
    end
  end
end
