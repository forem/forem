require 'spec_helper'

module FakeRedis
  describe "ListsMethods" do
    before(:each) do
      @client = Redis.new
    end

    it "should get an element from a list by its index" do
      @client.lpush("key1", "val1")
      @client.lpush("key1", "val2")

      expect(@client.lindex("key1", 0)).to eq("val2")
      expect(@client.lindex("key1", -1)).to eq("val1")
      expect(@client.lindex("key1", 3)).to eq(nil)
    end

    it "should insert an element before or after another element in a list" do
      @client.rpush("key1", "v1")
      @client.rpush("key1", "v3")
      @client.linsert("key1", :before, "v3", "v2")
      @client.linsert("key1", :after, "v3", 100)
      @client.linsert("key1", :before, 100, 99)

      expect(@client.lrange("key1", 0, -1)).to eq(["v1", "v2", "v3", "99", "100"])
    end

    it "inserts with case-insensitive position token" do
      @client.rpush("key1", "v1")
      @client.rpush("key1", "v4")

      @client.linsert("key1", :BEFORE, "v4", "v2")
      @client.linsert("key1", "Before", "v4", "v3")
      @client.linsert("key1", :AFTER, "v4", "v5")
      @client.linsert("key1", "After", "v5", "v6")

      expect(@client.lrange("key1", 0, -1)).to eq(%w(v1 v2 v3 v4 v5 v6))
    end

    it "should not insert if after/before index not found" do
      @client.rpush("key", "v1")
      expect(@client.linsert("key", :before, "unknown", "v2")).to eq(-1)
      expect(@client.linsert("key", :after, "unknown", "v3")).to eq(-1)

      expect(@client.lrange("key", 0, -1)).to eq(["v1"])
    end

    it 'should allow multiple values to be added to a list in a single rpush' do
      @client.rpush('key1', [1, 2, 3])
      expect(@client.lrange('key1', 0, -1)).to eq(['1', '2', '3'])
    end

    it 'should allow multiple values to be added to a list in a single lpush' do
      @client.lpush('key1', [1, 2, 3])
      expect(@client.lrange('key1', 0, -1)).to eq(['3', '2', '1'])
    end

    it "should error if an invalid where argument is given" do
      @client.rpush("key1", "v1")
      @client.rpush("key1", "v3")
      expect { @client.linsert("key1", :invalid, "v3", "v2") }.to raise_error(Redis::CommandError, "ERR syntax error")
    end

    it "should get the length of a list" do
      @client.rpush("key1", "v1")
      @client.rpush("key1", "v2")

      expect(@client.llen("key1")).to eq(2)
      expect(@client.llen("key2")).to eq(0)
    end

    it "should remove and get the first element in a list" do
      @client.rpush("key1", "v1")
      @client.rpush("key1", "v2")
      @client.rpush("key1", "v3")

      expect(@client.lpop("key1")).to eq("v1")
      expect(@client.lrange("key1", 0, -1)).to eq(["v2", "v3"])
    end

    it "should prepend a value to a list" do
      @client.rpush("key1", "v1")
      @client.rpush("key1", "v2")

      expect(@client.lrange("key1", 0, -1)).to eq(["v1", "v2"])
    end

    it "should prepend a value to a list, only if the list exists" do
      @client.lpush("key1", "v1")

      @client.lpushx("key1", "v2")
      @client.lpushx("key2", "v3")

      expect(@client.lrange("key1", 0, -1)).to eq(["v2", "v1"])
      expect(@client.llen("key2")).to eq(0)
    end

    it "should get a range of elements from a list" do
      @client.rpush("key1", "v1")
      @client.rpush("key1", "v2")
      @client.rpush("key1", "v3")

      expect(@client.lrange("key1", 1, -1)).to eq(["v2", "v3"])
      expect(@client.lrange("key1", -999, -1)).to eq(["v1", "v2", "v3"])
    end

    it "should remove elements from a list" do
      @client.rpush("key1", "v1")
      @client.rpush("key1", "v2")
      @client.rpush("key1", "v2")
      @client.rpush("key1", "v2")
      @client.rpush("key1", "v1")
      @client.rpush("key1", 42)

      expect(@client.lrem("key1", 1, "v1")).to eq(1)
      expect(@client.lrem("key1", -2, "v2")).to eq(2)
      expect(@client.lrem("key1", 0, 42)).to eq(1)
      expect(@client.llen("key1")).to eq(2)
    end

    it "should return 0 if key does not map to a list" do
      expect(@client.exists("nonexistant")).to eq(false)
      expect(@client.lrem("nonexistant", 0, "value")).to eq(0)
    end

    it "should remove list's key when list is empty" do
      @client.rpush("key1", "v1")
      @client.rpush("key1", "v2")
      @client.lrem("key1", 1, "v1")
      @client.lrem("key1", 1, "v2")

      expect(@client.exists("key1")).to eq(false)
    end

    it "should set the value of an element in a list by its index" do
      @client.rpush("key1", "one")
      @client.rpush("key1", "two")
      @client.rpush("key1", "three")

      @client.lset("key1", 0, "four")
      @client.lset("key1", -2, "five")
      @client.lset("key1", 2, 6)

      expect(@client.lrange("key1", 0, -1)).to eq(["four", "five", "6"])
      expect { @client.lset("key1", 4, "seven") }.to raise_error(Redis::CommandError, "ERR index out of range")
    end

    it "should trim a list to the specified range" do
      @client.rpush("key1", "one")
      @client.rpush("key1", "two")
      @client.rpush("key1", "three")

      expect(@client.ltrim("key1", 1, -1)).to eq("OK")
      expect(@client.lrange("key1", 0, -1)).to eq(["two", "three"])
    end


    context "when the list is smaller than the requested trim" do
      before { @client.rpush("listOfOne", "one") }

      context "trimming with a negative start (specifying a max)" do
        before { @client.ltrim("listOfOne", -5, -1) }

        it "returns the unmodified list" do
          expect(@client.lrange("listOfOne", 0, -1)).to eq(["one"])
        end
      end
    end

    context "when the list is larger than the requested trim" do
      before do
        @client.rpush("maxTest", "one")
        @client.rpush("maxTest", "two")
        @client.rpush("maxTest", "three")
        @client.rpush("maxTest", "four")
        @client.rpush("maxTest", "five")
        @client.rpush("maxTest", "six")
      end

      context "trimming with a negative start (specifying a max)" do
        before { @client.ltrim("maxTest", -5, -1) }

        it "should trim a list to the specified maximum size" do
          expect(@client.lrange("maxTest", 0, -1)).to eq(["two","three", "four", "five", "six"])
        end
      end
    end


    it "should remove and return the last element in a list" do
      @client.rpush("key1", "one")
      @client.rpush("key1", "two")
      @client.rpush("key1", "three")

      expect(@client.rpop("key1")).to eq("three")
      expect(@client.lrange("key1", 0, -1)).to eq(["one", "two"])
    end

    it "rpoplpush should remove the last element in a list, append it to another list and return it" do
      @client.rpush("key1", "one")
      @client.rpush("key1", "two")
      @client.rpush("key1", "three")

      expect(@client.rpoplpush("key1", "key2")).to eq("three")

      expect(@client.lrange("key1", 0, -1)).to eq(["one", "two"])
      expect(@client.lrange("key2", 0, -1)).to eq(["three"])
    end

    it "brpoplpush should remove the last element in a list, append it to another list and return it" do
      @client.rpush("key1", "one")
      @client.rpush("key1", "two")
      @client.rpush("key1", "three")

      expect(@client.brpoplpush("key1", "key2")).to eq("three")

      expect(@client.lrange("key1", 0, -1)).to eq(["one", "two"])
      expect(@client.lrange("key2", 0, -1)).to eq(["three"])
    end

    context 'when the source list is empty' do
      it 'rpoplpush does not add anything to the destination list' do
        @client.rpoplpush("source", "destination")

        expect(@client.lrange("destination", 0, -1)).to eq([])
      end

      it 'brpoplpush does not add anything to the destination list' do
        expect(@client.brpoplpush("source", "destination")).to be_nil

        expect(@client.lrange("destination", 0, -1)).to eq([])
      end
    end

    it "should append a value to a list" do
      @client.rpush("key1", "one")
      @client.rpush("key1", "two")

      expect(@client.lrange("key1", 0, -1)).to eq(["one", "two"])
    end

    it "should append a value to a list, only if the list exists" do
      @client.rpush("key1", "one")
      @client.rpushx("key1", "two")
      @client.rpushx("key2", "two")

      expect(@client.lrange("key1", 0, -1)).to eq(["one", "two"])
      expect(@client.lrange("key2", 0, -1)).to eq([])
    end

    it 'should not allow pushing empty list of objects' do
      expect { @client.lpush("key1", []) }.to raise_error(Redis::CommandError, /lpush[^x]/)
      expect { @client.lpush("key1", 1); @client.lpushx("key1", []) }.to raise_error(Redis::CommandError, /lpushx/)

      expect { @client.rpush("key1", []) }.to raise_error(Redis::CommandError, /rpush[^x]/)
      expect { @client.rpush("key1", 1); @client.rpushx("key1", []) }.to raise_error(Redis::CommandError, /rpushx/)
    end
  end
end
