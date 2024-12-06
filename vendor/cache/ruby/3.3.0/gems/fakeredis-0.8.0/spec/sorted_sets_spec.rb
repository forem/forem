require 'spec_helper'

module FakeRedis
  Infinity = 1.0/0.0

  describe "SortedSetsMethods" do
    before(:each) do
      @client = Redis.new
    end

    it "should add a member to a sorted set, or update its score if it already exists" do
      expect(@client.zadd("key", 1, "val")).to be(true)
      expect(@client.zscore("key", "val")).to eq(1.0)

      expect(@client.zadd("key", 2, "val")).to be(false)
      expect(@client.zscore("key", "val")).to eq(2.0)

      # These assertions only work in redis-rb v3.0.2 or higher
      expect(@client.zadd("key2", "inf", "val")).to eq(true)
      expect(@client.zscore("key2", "val")).to eq(Infinity)

      expect(@client.zadd("key3", "+inf", "val")).to eq(true)
      expect(@client.zscore("key3", "val")).to eq(Infinity)

      expect(@client.zadd("key4", "-inf", "val")).to eq(true)
      expect(@client.zscore("key4", "val")).to eq(-Infinity)
    end

    it "should return a nil score for value not in a sorted set or empty key" do
      @client.zadd "key", 1, "val"

      expect(@client.zscore("key", "val")).to eq(1.0)
      expect(@client.zscore("key", "val2")).to be_nil
      expect(@client.zscore("key2", "val")).to be_nil
    end

    it "should add multiple members to a sorted set, or update its score if it already exists" do
      expect(@client.zadd("key", [1, "val", 2, "val2"])).to eq(2)
      expect(@client.zscore("key", "val")).to eq(1)
      expect(@client.zscore("key", "val2")).to eq(2)

      expect(@client.zadd("key", [[5, "val"], [3, "val3"], [4, "val4"]])).to eq(2)
      expect(@client.zscore("key", "val")).to eq(5)
      expect(@client.zscore("key", "val2")).to eq(2)
      expect(@client.zscore("key", "val3")).to eq(3)
      expect(@client.zscore("key", "val4")).to eq(4)

      expect(@client.zadd("key", [[5, "val5"], [3, "val6"]])).to eq(2)
      expect(@client.zscore("key", "val5")).to eq(5)
      expect(@client.zscore("key", "val6")).to eq(3)
    end

    it "should error with wrong number of arguments when adding members" do
      expect { @client.zadd("key") }.to raise_error(ArgumentError, "wrong number of arguments")
      expect { @client.zadd("key", 1) }.to raise_error(ArgumentError, "wrong number of arguments")
      expect { @client.zadd("key", [1]) }.to raise_error(Redis::CommandError, "ERR wrong number of arguments for 'zadd' command")
      expect { @client.zadd("key", [1, "val", 2]) }.to raise_error(Redis::CommandError, "ERR syntax error")
      expect { @client.zadd("key", [[1, "val"], [2]]) }.to raise_error(Redis::CommandError, "ERR syntax error")
    end

    it "should allow floats as scores when adding or updating" do
      expect(@client.zadd("key", 4.321, "val")).to be(true)
      expect(@client.zscore("key", "val")).to eq(4.321)

      expect(@client.zadd("key", 54.3210, "val")).to be(false)
      expect(@client.zscore("key", "val")).to eq(54.321)
    end

    it "should allow strings that can be parsed as float when adding or updating" do
      expect(@client.zadd("key", "4.321", "val")).to be(true)
      expect(@client.zscore("key", "val")).to eq(4.321)

      expect(@client.zadd("key", "54.3210", "val")).to be(false)
      expect(@client.zscore("key", "val")).to eq(54.321)
    end

    it "should error when the score is not a valid float" do
      expect { @client.zadd("key", "score", "val") }.to raise_error(Redis::CommandError, "ERR value is not a valid float")
      expect { @client.zadd("key", {}, "val") }.to raise_error(Redis::CommandError, "ERR value is not a valid float")
      expect { @client.zadd("key", Time.now, "val") }.to raise_error(Redis::CommandError, "ERR value is not a valid float")
    end

    it "should remove members from sorted sets" do
      expect(@client.zrem("key", "val")).to be(false)
      expect(@client.zadd("key", 1, "val")).to be(true)
      expect(@client.zrem("key", "val")).to be(true)
    end

    it "should remove multiple members from sorted sets" do
      expect(@client.zrem("key2", %w(val))).to eq(0)
      expect(@client.zrem("key2", %w(val val2 val3))).to eq(0)

      @client.zadd("key2", 1, "val")
      @client.zadd("key2", 1, "val2")
      @client.zadd("key2", 1, "val3")

      expect(@client.zrem("key2", %w(val val2 val3 val4))).to eq(3)
    end

    it "should remove sorted set's key when it is empty" do
      @client.zadd("key", 1, "val")
      @client.zrem("key", "val")
      expect(@client.exists("key")).to eq(false)
    end

    it "should pop members with the highest scores from sorted set" do
      @client.zadd("key", [1, "val1", 2, "val2", 3, "val3"])
      expect(@client.zpopmax("key")).to eq(["val3", 3.0])
      expect(@client.zpopmax("key", 3)).to eq([["val2", 2.0], ["val1", 1.0]])
      expect(@client.zpopmax("nonexistent")).to eq(nil)
    end

    it "should pop members with the lowest scores from sorted set" do
      @client.zadd("key", [1, "val1", 2, "val2", 3, "val3"])
      expect(@client.zpopmin("key")).to eq(["val1", 1.0])
      expect(@client.zpopmin("key", 3)).to eq([["val2", 2.0], ["val3", 3.0]])
      expect(@client.zpopmin("nonexistent")).to eq(nil)
    end

    it "should pop members with the highest score from first sorted set that is non-empty" do
      @client.zadd("key1", [1, "val1", 2, "val2"])
      @client.zadd("key2", [3, "val3"])
      expect(@client.bzpopmax("nonexistent", "key1", "key2", 0)).to eq(["key1", "val2", 2.0])
      expect(@client.bzpopmax("nonexistent")).to eq(nil)
    end

    it "should pop members with the lowest score from first sorted set that is non-empty" do
      @client.zadd("key1", [1, "val1", 2, "val2"])
      @client.zadd("key2", [3, "val3"])
      expect(@client.bzpopmin("nonexistent", "key1", "key2", 0)).to eq(["key1", "val1", 1.0])
      expect(@client.bzpopmin("nonexistent")).to eq(nil)
    end

    it "should get the number of members in a sorted set" do
      @client.zadd("key", 1, "val2")
      @client.zadd("key", 2, "val1")
      @client.zadd("key", 5, "val3")

      expect(@client.zcard("key")).to eq(3)
    end

    it "should count the members in a sorted set with scores within the given values" do
      @client.zadd("key", 1, "val1")
      @client.zadd("key", 2, "val2")
      @client.zadd("key", 3, "val3")

      expect(@client.zcount("key", 2, 3)).to eq(2)
    end

    it "should increment the score of a member in a sorted set" do
      @client.zadd("key", 1, "val1")
      expect(@client.zincrby("key", 2, "val1")).to eq(3)
      expect(@client.zscore("key", "val1")).to eq(3)
    end

    it "initializes the sorted set if the key wasnt already set" do
      expect(@client.zincrby("key", 1, "val1")).to eq(1)
    end

    it "should convert the key to a string for zscore" do
      @client.zadd("key", 1, 1)
      expect(@client.zscore("key", 1)).to eq(1)
    end

    # These won't pass until redis-rb releases v3.0.2
    it "should handle infinity values when incrementing a sorted set key" do
      expect(@client.zincrby("bar", "+inf", "s2")).to eq(Infinity)
      expect(@client.zincrby("bar", "-inf", "s1")).to eq(-Infinity)
    end

    it "should return a range of members in a sorted set, by index" do
      @client.zadd("key", 1, "one")
      @client.zadd("key", 2, "two")
      @client.zadd("key", 3, "three")

      expect(@client.zrange("key", 0, -1)).to eq(["one", "two", "three"])
      expect(@client.zrange("key", 1, 2)).to eq(["two", "three"])
      expect(@client.zrange("key", -50, -2)).to eq(["one", "two"])
      expect(@client.zrange("key", 0, -1, :withscores => true)).to eq([["one", 1], ["two", 2], ["three", 3]])
      expect(@client.zrange("key", 1, 2, :with_scores => true)).to eq([["two", 2], ["three", 3]])
    end

    it "should sort zrange results logically" do
      @client.zadd("key", 5, "val2")
      @client.zadd("key", 5, "val3")
      @client.zadd("key", 5, "val1")

      expect(@client.zrange("key", 0, -1)).to eq(%w(val1 val2 val3))
      expect(@client.zrange("key", 0, -1, :with_scores => true)).to eq([["val1", 5], ["val2", 5], ["val3", 5]])
    end

    it "should return a reversed range of members in a sorted set, by index" do
      @client.zadd("key", 1, "one")
      @client.zadd("key", 2, "two")
      @client.zadd("key", 3, "three")

      expect(@client.zrevrange("key", 0, -1)).to eq(["three", "two", "one"])
      expect(@client.zrevrange("key", 1, 2)).to eq(["two", "one"])
      expect(@client.zrevrange("key", 0, -1, :withscores => true)).to eq([["three", 3], ["two", 2], ["one", 1]])
      expect(@client.zrevrange("key", 0, -1, :with_scores => true)).to eq([["three", 3], ["two", 2], ["one", 1]])
    end

    it "should return a range of members in a sorted set, by score" do
      @client.zadd("key", 1, "one")
      @client.zadd("key", 2, "two")
      @client.zadd("key", 3, "three")

      expect(@client.zrangebyscore("key", 0, 100)).to eq(["one", "two", "three"])
      expect(@client.zrangebyscore("key", 1, 2)).to eq(["one", "two"])
      expect(@client.zrangebyscore("key", 1, '(2')).to eq(['one'])
      expect(@client.zrangebyscore("key", '(1', 2)).to eq(['two'])
      expect(@client.zrangebyscore("key", '(1', '(2')).to eq([])
      expect(@client.zrangebyscore("key", 0, 100, :withscores => true)).to eq([["one", 1], ["two", 2], ["three", 3]])
      expect(@client.zrangebyscore("key", 1, 2, :with_scores => true)).to eq([["one", 1], ["two", 2]])
      expect(@client.zrangebyscore("key", 0, 100, :limit => [0, 1])).to eq(["one"])
      expect(@client.zrangebyscore("key", 0, 100, :limit => [0, -1])).to eq(["one", "two", "three"])
      expect(@client.zrangebyscore("key", 0, 100, :limit => [1, -1], :with_scores => true)).to eq([["two", 2], ["three", 3]])
      expect(@client.zrangebyscore("key", '-inf', '+inf')).to eq(["one", "two", "three"])
      expect(@client.zrangebyscore("key", 2, '+inf')).to eq(["two", "three"])
      expect(@client.zrangebyscore("key", '-inf', 2)).to eq(['one', "two"])

      expect(@client.zrangebyscore("badkey", 1, 2)).to eq([])
    end

    it "should return a reversed range of members in a sorted set, by score" do
      @client.zadd("key", 1, "one")
      @client.zadd("key", 2, "two")
      @client.zadd("key", 3, "three")

      expect(@client.zrevrangebyscore("key", 100, 0)).to eq(["three", "two", "one"])
      expect(@client.zrevrangebyscore("key", 2, 1)).to eq(["two", "one"])
      expect(@client.zrevrangebyscore("key", 1, 2)).to eq([])
      expect(@client.zrevrangebyscore("key", 2, 1, :with_scores => true)).to eq([["two", 2.0], ["one", 1.0]])
      expect(@client.zrevrangebyscore("key", 100, 0, :limit => [0, 1])).to eq(["three"])
      expect(@client.zrevrangebyscore("key", 100, 0, :limit => [0, -1])).to eq(["three", "two", "one"])
      expect(@client.zrevrangebyscore("key", 100, 0, :limit => [1, -1], :with_scores => true)).to eq([["two", 2.0], ["one", 1.0]])
    end

    it "should determine the index of a member in a sorted set" do
      @client.zadd("key", 1, "one")
      @client.zadd("key", 2, "two")
      @client.zadd("key", 3, "three")

      expect(@client.zrank("key", "three")).to eq(2)
      expect(@client.zrank("key", "four")).to be_nil
    end

    it "should determine the reversed index of a member in a sorted set" do
      @client.zadd("key", 1, "one")
      @client.zadd("key", 2, "two")
      @client.zadd("key", 3, "three")

      expect(@client.zrevrank("key", "three")).to eq(0)
      expect(@client.zrevrank("key", "four")).to be_nil
    end

    it "should not raise errors for zrank() on accessing a non-existing key in a sorted set" do
      expect(@client.zrank("no_such_key", "no_suck_id")).to be_nil
    end

    it "should not raise errors for zrevrank() on accessing a non-existing key in a sorted set" do
      expect(@client.zrevrank("no_such_key", "no_suck_id")).to be_nil
    end

    describe "#zinterstore" do
      before do
        @client.zadd("key1", 1, "one")
        @client.zadd("key1", 2, "two")
        @client.zadd("key1", 3, "three")
        @client.zadd("key2", 5, "two")
        @client.zadd("key2", 7, "three")
        @client.sadd("key3", 'one')
        @client.sadd("key3", 'two')
      end

      it "should intersect two keys with custom scores" do
        expect(@client.zinterstore("out", ["key1", "key2"])).to eq(2)
        expect(@client.zrange("out", 0, -1, :with_scores => true)).to eq([['two', (2 + 5)], ['three', (3 + 7)]])
      end

      it "should intersect two keys with a default score" do
        expect(@client.zinterstore("out", ["key1", "key3"])).to eq(2)
        expect(@client.zrange("out", 0, -1, :with_scores => true)).to eq([['one', (1 + 1)], ['two', (2 + 1)]])
      end

      it "should intersect more than two keys" do
        expect(@client.zinterstore("out", ["key1", "key2", "key3"])).to eq(1)
        expect(@client.zrange("out", 0, -1, :with_scores => true)).to eq([['two', (2 + 5 + 1)]])
      end

      it "should not intersect an unknown key" do
        expect(@client.zinterstore("out", ["key1", "no_key"])).to eq(0)
        expect(@client.zrange("out", 0, -1, :with_scores => true)).to eq([])
      end

      it "should intersect two keys by minimum values" do
        expect(@client.zinterstore("out", ["key1", "key2"], :aggregate => :min)).to eq(2)
        expect(@client.zrange("out", 0, -1, :with_scores => true)).to eq([["two", 2], ["three", 3]])
      end

      it "should intersect two keys by maximum values" do
        expect(@client.zinterstore("out", ["key1", "key2"], :aggregate => :max)).to eq(2)
        expect(@client.zrange("out", 0, -1, :with_scores => true)).to eq([["two", 5], ["three", 7]])
      end

      it "should intersect two keys by explicitly summing values" do
        expect(@client.zinterstore("out", %w(key1 key2), :aggregate => :sum)).to eq(2)
        expect(@client.zrange("out", 0, -1, :with_scores => true)).to eq([["two", (2 + 5)], ["three", (3 + 7)]])
      end

      it "should intersect two keys with weighted values" do
        expect(@client.zinterstore("out", %w(key1 key2), :weights => [10, 1])).to eq(2)
        expect(@client.zrange("out", 0, -1, :with_scores => true)).to eq([["two", (2 * 10 + 5)], ["three", (3 * 10 + 7)]])
      end

      it "should intersect two keys with weighted minimum values" do
        expect(@client.zinterstore("out", %w(key1 key2), :weights => [10, 1], :aggregate => :min)).to eq(2)
        expect(@client.zrange("out", 0, -1, :with_scores => true)).to eq([["two", 5], ["three", 7]])
      end

      it "should intersect two keys with weighted maximum values" do
        expect(@client.zinterstore("out", %w(key1 key2), :weights => [10, 1], :aggregate => :max)).to eq(2)
        expect(@client.zrange("out", 0, -1, :with_scores => true)).to eq([["two", (2 * 10)], ["three", (3 * 10)]])
      end

      it "should error without enough weights given" do
        expect { @client.zinterstore("out", %w(key1 key2), :weights => []) }.to raise_error(Redis::CommandError, "ERR syntax error")
        expect { @client.zinterstore("out", %w(key1 key2), :weights => [10]) }.to raise_error(Redis::CommandError, "ERR syntax error")
      end

      it "should error with too many weights given" do
        expect { @client.zinterstore("out", %w(key1 key2), :weights => [10, 1, 1]) }.to raise_error(Redis::CommandError, "ERR syntax error")
      end

      it "should error with an invalid aggregate" do
        expect { @client.zinterstore("out", %w(key1 key2), :aggregate => :invalid) }.to raise_error(Redis::CommandError, "ERR syntax error")
      end

      it 'stores nothing when there are no members in common' do
        @client.zadd("k1", 1, "1")
        @client.zadd("k1", 1, "2")
        @client.sadd("k2", "a")
        @client.sadd("k3", "b")

        expect(@client.zinterstore("out", %w(k1 k2 k3))).to eq(0)
        expect(@client.zrange("out", 0, -1)).to eq([])
      end

      it 'handles range start being higher than number of members' do
        @client.zadd("key", 1, "1")

        expect(@client.zrange("key", 10, 10)).to eq([])
      end
    end

    context "zremrangebyscore" do
      it "should remove items by score" do
        @client.zadd("key", 1, "one")
        @client.zadd("key", 2, "two")
        @client.zadd("key", 3, "three")

        expect(@client.zremrangebyscore("key", 0, 2)).to eq(2)
        expect(@client.zcard("key")).to eq(1)
      end

      it "should remove items by score with infinity" do # Issue #50
        @client.zadd("key", 10.0, "one")
        @client.zadd("key", 20.0, "two")
        @client.zadd("key", 30.0, "three")
        expect(@client.zremrangebyscore("key", "-inf", "+inf")).to eq(3)
        expect(@client.zcard("key")).to eq(0)
        expect(@client.zscore("key", "one")).to be_nil
        expect(@client.zscore("key", "two")).to be_nil
        expect(@client.zscore("key", "three")).to be_nil
      end

      it "should return 0 if the key didn't exist" do
        expect(@client.zremrangebyscore("key", 0, 2)).to eq(0)
      end
    end

    context '#zremrangebyrank' do
      it 'removes all elements with in the given range' do
        @client.zadd("key", 1, "one")
        @client.zadd("key", 2, "two")
        @client.zadd("key", 3, "three")

        expect(@client.zremrangebyrank("key", 0, 1)).to eq(2)
        expect(@client.zcard('key')).to eq(1)
      end

      it 'handles out of range requests' do
        @client.zadd("key", 1, "one")
        @client.zadd("key", 2, "two")
        @client.zadd("key", 3, "three")

        expect(@client.zremrangebyrank("key", 25, -1)).to eq(0)
        expect(@client.zcard('key')).to eq(3)
      end

      it "should return 0 if the key didn't exist" do
        expect(@client.zremrangebyrank("key", 0, 1)).to eq(0)
      end
    end

    describe "#zunionstore" do
      before do
        @client.zadd("key1", 1, "val1")
        @client.zadd("key1", 2, "val2")
        @client.zadd("key1", 3, "val3")
        @client.zadd("key2", 5, "val2")
        @client.zadd("key2", 7, "val3")
        @client.sadd("key3", "val1")
        @client.sadd("key3", "val2")
      end

      it "should union two keys with custom scores" do
        expect(@client.zunionstore("out", %w(key1 key2))).to eq(3)
        expect(@client.zrange("out", 0, -1, :with_scores => true)).to eq([["val1", 1], ["val2", (2 + 5)], ["val3", (3 + 7)]])
      end

      it "should union two keys with a default score" do
        expect(@client.zunionstore("out", %w(key1 key3))).to eq(3)
        expect(@client.zrange("out", 0, -1, :with_scores => true)).to eq([["val1", (1 + 1)], ["val2", (2 + 1)], ["val3", 3]])
      end

      it "should union more than two keys" do
        expect(@client.zunionstore("out", %w(key1 key2 key3))).to eq(3)
        expect(@client.zrange("out", 0, -1, :with_scores => true)).to eq([["val1", (1 + 1)], ["val2", (2 + 5 + 1)], ["val3", (3 + 7)]])
      end

      it "should union with an unknown key" do
        expect(@client.zunionstore("out", %w(key1 no_key))).to eq(3)
        expect(@client.zrange("out", 0, -1, :with_scores => true)).to eq([["val1", 1], ["val2", 2], ["val3", 3]])
      end

      it "should union two keys by minimum values" do
        expect(@client.zunionstore("out", %w(key1 key2), :aggregate => :min)).to eq(3)
        expect(@client.zrange("out", 0, -1, :with_scores => true)).to eq([["val1", 1], ["val2", 2], ["val3", 3]])
      end

      it "should union two keys by maximum values" do
        expect(@client.zunionstore("out", %w(key1 key2), :aggregate => :max)).to eq(3)
        expect(@client.zrange("out", 0, -1, :with_scores => true)).to eq([["val1", 1], ["val2", 5], ["val3", 7]])
      end

      it "should union two keys by explicitly summing values" do
        expect(@client.zunionstore("out", %w(key1 key2), :aggregate => :sum)).to eq(3)
        expect(@client.zrange("out", 0, -1, :with_scores => true)).to eq([["val1", 1], ["val2", (2 + 5)], ["val3", (3 + 7)]])
      end

      it "should union two keys with weighted values" do
        expect(@client.zunionstore("out", %w(key1 key2), :weights => [10, 1])).to eq(3)
        expect(@client.zrange("out", 0, -1, :with_scores => true)).to eq([["val1", (1 * 10)], ["val2", (2 * 10 + 5)], ["val3", (3 * 10 + 7)]])
      end

      it "should union two keys with weighted minimum values" do
        expect(@client.zunionstore("out", %w(key1 key2), :weights => [10, 1], :aggregate => :min)).to eq(3)
        expect(@client.zrange("out", 0, -1, :with_scores => true)).to eq([["val2", 5], ["val3", 7], ["val1", (1 * 10)]])
      end

      it "should union two keys with weighted maximum values" do
        expect(@client.zunionstore("out", %w(key1 key2), :weights => [10, 1], :aggregate => :max)).to eq(3)
        expect(@client.zrange("out", 0, -1, :with_scores => true)).to eq([["val1", (1 * 10)], ["val2", (2 * 10)], ["val3", (3 * 10)]])
      end

      it "should error without enough weights given" do
        expect { @client.zunionstore("out", %w(key1 key2), :weights => []) }.to raise_error(Redis::CommandError, "ERR syntax error")
        expect { @client.zunionstore("out", %w(key1 key2), :weights => [10]) }.to raise_error(Redis::CommandError, "ERR syntax error")
      end

      it "should error with too many weights given" do
        expect { @client.zunionstore("out", %w(key1 key2), :weights => [10, 1, 1]) }.to raise_error(Redis::CommandError, "ERR syntax error")
      end

      it "should error with an invalid aggregate" do
        expect { @client.zunionstore("out", %w(key1 key2), :aggregate => :invalid) }.to raise_error(Redis::CommandError, "ERR syntax error")
      end
    end

    #it "should remove all members in a sorted set within the given indexes"

    #it "should return a range of members in a sorted set, by index, with scores ordered from high to low"

    #it "should return a range of members in a sorted set, by score, with scores ordered from high to low"

    #it "should determine the index of a member in a sorted set, with scores ordered from high to low"

    #it "should get the score associated with the given member in a sorted set"

    #it "should add multiple sorted sets and store the resulting sorted set in a new key"

    it "zrem should remove members add by zadd" do
      @client.zadd("key1", 1, 3)
      @client.zrem("key1", 3)
      expect(@client.zscore("key1", 3)).to be_nil
    end

    describe "#zscan" do
      before { 50.times { |x| @client.zadd("key", x, "key #{x}") } }

      it 'with no arguments should return 10 numbers in ascending order' do
        result = @client.zscan("key", 0)[1]
        expect(result).to eq(result.sort { |x, y| x[1] <=> y[1] })
        expect(result.count).to eq(10)
      end

      it 'with a count should return that number of members' do
        expect(@client.zscan("key", 0, count: 2)).to eq(["2", [["key 0", 0.0], ["key 1", 1.0]]])
      end

      it 'with a count greater than the number of members, returns all the members in asc order' do
        result = @client.zscan("key", 0, count: 1000)[1]
        expect(result).to eq(result.sort { |x, y| x[1] <=> y[1] })
        expect(result.size).to eq(50)
      end

      it 'with match, should return key-values where the key matches' do
        @client.zadd("key", 1.0, "blah")
        @client.zadd("key", 2.0, "bluh")
        result = @client.zscan("key", 0, count: 100, match: "key*")[1]
        expect(result).to_not include(["blah", 1.0])
        expect(result).to_not include(["bluh", 2.0])
      end
    end

    describe "#zscan_each" do
      before { 50.times { |x| @client.zadd("key", x, "key #{x}") } }

      it 'enumerates over the items in the sorted set' do
        expect(@client.zscan_each("key").to_a).to eq(@client.zscan("key", 0, count: 50)[1])
      end
    end

    describe '#zrangebylex' do
      before { @client.zadd "myzset", [0, 'a', 0, 'b', 0, 'd', 0, 'c'] }

      it "should return empty list for '+'..'-' range" do
        ranged = @client.zrangebylex "myzset", "+", "-"
        expect(ranged).to be_empty
      end

      it "should return all elements for '-'..'+' range" do
        ranged = @client.zrangebylex "myzset", "-", "+"
        expect(ranged).to eq %w(a b c d)
      end

      it "should include values starting with [ symbol" do
        ranged = @client.zrangebylex "myzset", "-", "[c"
        expect(ranged).to eq %w(a b c)
      end

      it "should exclude values with ( symbol" do
        ranged = @client.zrangebylex "myzset", "-", "(c"
        expect(ranged).to eq %w(a b)
      end

      it "should work with both [ and ( properly" do
        ranged = @client.zrangebylex "myzset", "[aaa", "(d"
        expect(ranged).to eq %w(b c)
      end

      it "should return empty array if key is not exist" do
        ranged = @client.zrangebylex "puppies", "-", "+"
        expect(ranged).to be_empty
      end

      it 'should raise error for invalid range when range is invalid' do
        expect{ @client.zrangebylex "myzset", "-", "d" }.to raise_error(Redis::CommandError, "ERR min or max not valid string range item")
      end

      it "should limit and offset values as 4th argument" do
        ranged = @client.zrangebylex "myzset", "-", "+", limit: [1, 3]
        expect(ranged).to eq %w(b c d)
      end
    end

    describe "#zrevrangebylex" do
      before { @client.zadd "myzset", [0, 'a', 0, 'b', 0, 'd', 0, 'c'] }

      it "should return empty list for '-'..'+' range" do
        ranged = @client.zrevrangebylex "myzset", "-", "+"
        expect(ranged).to be_empty
      end

      it "should return all elements for '+'..'-' range in descending order" do
        ranged = @client.zrevrangebylex "myzset", "+", "-"
        expect(ranged).to eq %w(d c b a)
      end

      it "should include values starting with [ symbol" do
        ranged = @client.zrevrangebylex "myzset", "[c", "-"
        expect(ranged).to eq %w(c b a)
      end

      it "should exclude values with ( symbol" do
        ranged = @client.zrevrangebylex "myzset", "+", "(c"
        expect(ranged).to eq %w(d)
      end

      it "should work with both [ and ( properly" do
        ranged = @client.zrevrangebylex "myzset", "(d", "[aaa"
        expect(ranged).to eq %w(c b)
      end

      it "should return empty array if key does not exist" do
        ranged = @client.zrevrangebylex "puppies", "+", "-"
        expect(ranged).to be_empty
      end

      it 'should raise error for invalid range when range is invalid' do
        expect { @client.zrevrangebylex "myzset", "-", "d" }.to raise_error(Redis::CommandError, "ERR min or max not valid string range item")
      end

      it "should limit and offset values as 4th argument" do
        pending "current stable (3.2.0) redis-rb doesn't support limit option"

        ranged = @client.zrevrangebylex "myzset", "+", "-", limit: [0, 3]
        expect(ranged).to eq %w(d c b)
      end
    end

    describe "#zadd" do
      context "with {incr: true}" do
        before { @client.zadd("key", 1, "existing") }
        it "should increment the element's score with the provided value" do
          @client.zadd("key", 99, "existing", incr: true)
          expect(@client.zscore("key", "existing")).to eq(100.0)

          @client.zadd("key", 2, "new", incr: true)
          expect(@client.zscore("key", "new")).to eq(2.0)
        end

        it "should error when trying to add multiple increment-element pairs" do
          expect {
            @client.zadd("key", [1, "member1", 2, "member2"], incr: true)
          }.to raise_error(Redis::CommandError, "ERR INCR option supports a single increment-element pair")
        end
      end

      context "with {nx: true}" do
        before { @client.zadd("key", [1, "existing1", 2, "existing2"]) }
        it "should add new elements but not update the scores of existing elements" do
          @client.zadd("key", [101, "existing1", 3, "new"], nx: true)

          expect(@client.zscore("key", "existing1")).to eq(1.0)
          expect(@client.zscore("key", "new")).to eq(3.0)

          @client.zadd("key", 102, "existing2", nx: true)
          expect(@client.zscore("key", "existing2")).to eq(2.0)
        end
      end

      context "with {xx: true}" do
        before { @client.zadd("key", 1, "existing") }
        it "should not add new elements" do
          expect(@client.zadd("key", 1, "new1", xx: true)).to eq(false)
          expect(@client.zscore("key", "new1")).to be_nil

          expect(@client.zadd("key", [11, "existing", 2, "new2"], xx: true)).to eq(0)
          expect(@client.zscore("key", "existing")).to eq(11.0)
          expect(@client.zscore("key", "new2")).to be_nil
        end
      end

      context "with {ch: true}" do
        it "should return the number of new elements added plus the number of existing elements for which the score was updated" do
          expect(@client.zadd("key", 1, "first", ch: true)).to eq(true)

          expect(@client.zadd("key", [1, "first", 2, "second"], ch: true)).to eq(1.0)
          expect(@client.zadd("key", [11, "first", 2, "second"], ch: true)).to eq(1.0)
          expect(@client.zadd("key", [99, "first", 99, "second"], ch: true)).to eq(2.0)
          expect(@client.zadd("key", [111, "first", 22, "second", 3, "third"], ch: true)).to eq(3.0)
        end
      end

      context "with {nx: true, xx: true}" do
        it "should error" do
          expect{
            @client.zadd("key", 1, "value", nx: true, xx: true)
          }.to raise_error(Redis::CommandError, "ERR XX and NX options at the same time are not compatible")
        end
      end

      context "with {nx: true, incr: true}" do
        let(:options) { {nx: true, incr: true} }
        it "should increment to the provided score only if the element is new and return the element's score" do
          expect(@client.zadd("key", 1, "first", options)).to eq(1.0)
          expect(@client.zscore("key", "first")).to eq(1.0)

          expect(@client.zadd("key", 2, "second", options)).to eq(2.0)
          expect(@client.zscore("key", "second")).to eq(2.0)

          expect(@client.zadd("key", 99, "first", options)).to be_nil
          expect(@client.zscore("key", "first")).to eq(1.0)
        end
      end

      context "with {nx: true, ch: true}" do
        let(:options) { {nx: true, ch: true} }
        it "should add only new elements, not update existing elements, and return the number of added elements" do
          expect(@client.zadd("key", 1, "first", options)).to eq(true)
          expect(@client.zadd("key", 1, "first", options)).to eq(false)

          # add two new elements
          expect(@client.zadd("key", [99, "first", 2, "second", 3, "third"], options)).to eq(2)
          expect(@client.zscore("key", "first")).to eq(1.0)
        end
      end

      context "with {nx: true, incr: true, ch: true}" do
        let(:options) { {nx: true, incr: true, ch: true} }

        it "should add only new elements" do
          expect(@client.zadd("key", 1, "first", options)).to eq(1.0)
          expect(@client.zadd("key", 99, "first", options)).to be_nil
          expect(@client.zscore("key", "first")).to eq(1.0)
        end

        # when INCR is present, return value is always the new score of member
        it "should return the score of the new member" do
          expect(@client.zadd("key", 2, "second", options)).to eq(2.0)
        end

        it "should return nil when the member already exists" do
          @client.zadd("key", 1, "first")
          expect(@client.zadd("key", 99, "first", options)).to be_nil
        end
      end

      context "with {xx: true, incr: true}" do
        let(:options) { {xx: true, incr: true} }
        before { @client.zadd("key", 1, "existing") }

        it "should return nil if the member does not already exist" do
          expect(@client.zadd("key", 1, "new1", options)).to be_nil
          expect(@client.zscore("key", "new1")).to be_nil
        end

        it "should increment only existing elements" do
          expect(@client.zadd("key", [11, "existing"], options)).to eq(12.0)
          expect(@client.zscore("key", "existing")).to eq(12.0)
        end
      end

      context "with {xx: true, ch: true}" do
        let(:options) { {xx: true, ch: true} }
        it "should return the number of updated elements and not add new members" do
          @client.zadd("key", 1, "first")

          expect(@client.zadd("key", 99, "first", options)).to eq(true)
          expect(@client.zadd("key", [100, "first", 2, "second"], options)).to eq(1.0)
          expect(@client.zscore("key", "second")).to be_nil
        end
      end

      context "with {xx: true, incr: true, ch: true}" do
        let(:options) { {xx: true, incr: true, ch: true} }
        before { @client.zadd("key", 1, "existing") }

        # when INCR is present, return value is always the new score of member
        it "should return the new score of the inserted member" do
          expect(@client.zadd("key", 2, "existing", options)).to eq(3.0)
        end

        it "should increment only existing elements" do
          expect(@client.zadd("key", 1, "new", options)).to be_nil
        end
      end
    end
  end
end
