require 'spec_helper'

module FakeRedis
  describe "SetsMethods" do
    before(:each) do
      @client = Redis.new
    end

    it "should add a member to a set" do
      expect(@client.sadd("key", "value")).to eq(true)
      expect(@client.sadd("key", "value")).to eq(false)

      expect(@client.smembers("key")).to eq(["value"])
    end

    it "should raise error if command arguments count is not enough" do
      expect { @client.sadd("key", []) }.to raise_error(Redis::CommandError, "ERR wrong number of arguments for 'sadd' command")
      expect { @client.sinter(*[]) }.to raise_error(Redis::CommandError, "ERR wrong number of arguments for 'sinter' command")
      expect { @client.sinter([]) }.to raise_error(Redis::CommandError, "ERR wrong number of arguments for 'sinter' command")
      expect { @client.sunion(*[]) }.to raise_error(Redis::CommandError, "ERR wrong number of arguments for 'sunion' command")
      expect { @client.sunion([]) }.to raise_error(Redis::CommandError, "ERR wrong number of arguments for 'sunion' command")
      expect { @client.srem("key", []) }.to raise_error(Redis::CommandError, "ERR wrong number of arguments for 'srem' command")

      expect(@client.smembers("key")).to be_empty
    end

    it "should add multiple members to a set" do
      expect(@client.sadd("key", %w(value other something more))).to eq(4)
      expect(@client.sadd("key", %w(and additional values))).to eq(3)
      expect(@client.smembers("key")).to match_array(["value", "other", "something", "more", "and", "additional", "values"])
    end

    it "should get the number of members in a set" do
      @client.sadd("key", "val1")
      @client.sadd("key", "val2")

      expect(@client.scard("key")).to eq(2)
    end

    it "should subtract multiple sets" do
      @client.sadd("key1", "a")
      @client.sadd("key1", "b")
      @client.sadd("key1", "c")
      @client.sadd("key1", "d")
      @client.sadd("key2", "c")
      @client.sadd("key3", "a")
      @client.sadd("key3", "c")
      @client.sadd("key3", "e")

      expect(@client.sdiff("key1", "key2", "key3")).to match_array(["b", "d"])
      expect(@client.sdiff("key1", ["key2", "key3"])).to match_array(["b", "d"])
    end

    it "should subtract from a nonexistent set" do
      @client.sadd("key2", "a")
      @client.sadd("key2", "b")

      expect(@client.sdiff("key1", "key2")).to eq([])
      expect(@client.sdiff(["key1", "key2"])).to eq([])
    end

    it "should subtract multiple sets and store the resulting set in a key" do
      @client.sadd("key1", "a")
      @client.sadd("key1", "b")
      @client.sadd("key1", "c")
      @client.sadd("key1", "d")
      @client.sadd("key2", "c")
      @client.sadd("key3", "a")
      @client.sadd("key3", "c")
      @client.sadd("key3", "e")
      @client.sdiffstore("key", "key1", "key2", "key3")
      @client.sdiffstore("new_key", "key1", ["key2", "key3"])

      expect(@client.smembers("key")).to match_array(["b", "d"])
      expect(@client.smembers("new_key")).to match_array(["b", "d"])
    end

    it "should intersect multiple sets" do
      @client.sadd("key1", "a")
      @client.sadd("key1", "b")
      @client.sadd("key1", "c")
      @client.sadd("key1", "d")
      @client.sadd("key2", "c")
      @client.sadd("key3", "a")
      @client.sadd("key3", "c")
      @client.sadd("key3", "e")

      expect(@client.sinter("key1", "key2", "key3")).to eq(["c"])
      expect(@client.sinter(["key1", "key2", "key3"])).to eq(["c"])
    end

    it "should intersect multiple sets and store the resulting set in a key" do
      @client.sadd("key1", "a")
      @client.sadd("key1", "b")
      @client.sadd("key1", "c")
      @client.sadd("key1", "d")
      @client.sadd("key2", "c")
      @client.sadd("key3", "a")
      @client.sadd("key3", "c")
      @client.sadd("key3", "e")
      @client.sinterstore("key", "key1", "key2", "key3")
      @client.sinterstore("new_key", ["key1", "key2", "key3"])

      expect(@client.smembers("key")).to eq(["c"])
      expect(@client.smembers("new_key")).to eq(["c"])
    end

    it "should determine if a given value is a member of a set" do
      @client.sadd("key1", "a")

      expect(@client.sismember("key1", "a")).to eq(true)
      expect(@client.sismember("key1", "b")).to eq(false)
      expect(@client.sismember("key2", "a")).to eq(false)
    end

    it "should get all the members in a set" do
      @client.sadd("key", "a")
      @client.sadd("key", "b")
      @client.sadd("key", "c")
      @client.sadd("key", "d")

      expect(@client.smembers("key")).to match_array(["a", "b", "c", "d"])
    end

    it "should move a member from one set to another" do
      @client.sadd("key1", "a")
      @client.sadd("key1", "b")
      @client.sadd("key2", "c")
      expect(@client.smove("key1", "key2", "a")).to eq(true)
      expect(@client.smove("key1", "key2", "a")).to eq(false)

      expect(@client.smembers("key1")).to eq(["b"])
      expect(@client.smembers("key2")).to match_array(["c", "a"])
    end

    it "should remove and return a random member from a set" do
      @client.sadd("key1", "a")
      @client.sadd("key1", "b")

      expect(["a", "b"].include?(@client.spop("key1"))).to be true
      expect(["a", "b"].include?(@client.spop("key1"))).to be true
      expect(@client.spop("key1")).to be_nil
    end

    it "should get a random member from a set" do
      @client.sadd("key1", "a")
      @client.sadd("key1", "b")

      expect(["a", "b"].include?(@client.spop("key1"))).to be true
    end

    it "should pop multiple members from a set" do
      @client.sadd("key1", "a")
      @client.sadd("key1", "b")
      @client.sadd("key1", "c")

      vals = @client.spop("key1", 2)
      expect(vals.count).to eq(2)
      vals.each { |v| expect(["a", "b", "c"].include?(v)).to be true }

      new_vals = @client.spop("key1", 2)
      expect(new_vals.count).to eq(1)
      expect(["a", "b", "c"].include?(new_vals.first)).to be true

      expect(["a", "b", "c"]).to eq((vals + new_vals).sort)
    end

    it "should remove a member from a set" do
      @client.sadd("key1", "a")
      @client.sadd("key1", "b")
      expect(@client.srem("key1", "a")).to eq(true)
      expect(@client.srem("key1", "a")).to eq(false)

      expect(@client.smembers("key1")).to eq(["b"])
    end

    it "should remove multiple members from a set" do
      @client.sadd("key1", "a")
      @client.sadd("key1", "b")

      expect(@client.srem("key1", [ "a", "b"])).to eq(2)
      expect(@client.smembers("key1")).to be_empty
    end

    it "should remove the set's key once it's empty" do
      @client.sadd("key1", "a")
      @client.sadd("key1", "b")
      @client.srem("key1", "b")
      @client.srem("key1", "a")

      expect(@client.exists("key1")).to eq(false)
    end

    it "should add multiple sets" do
      @client.sadd("key1", "a")
      @client.sadd("key1", "b")
      @client.sadd("key1", "c")
      @client.sadd("key1", "d")
      @client.sadd("key2", "c")
      @client.sadd("key3", "a")
      @client.sadd("key3", "c")
      @client.sadd("key3", "e")

      expect(@client.sunion("key1", "key2", "key3")).to match_array(["a", "b", "c", "d", "e"])
    end

    it "should add multiple sets and store the resulting set in a key" do
      @client.sadd("key1", "a")
      @client.sadd("key1", "b")
      @client.sadd("key1", "c")
      @client.sadd("key1", "d")
      @client.sadd("key2", "c")
      @client.sadd("key3", "a")
      @client.sadd("key3", "c")
      @client.sadd("key3", "e")
      @client.sunionstore("key", "key1", "key2", "key3")

      expect(@client.smembers("key")).to match_array(["a", "b", "c", "d", "e"])
    end
  end

  describe 'srandmember' do
    before(:each) do
      @client = Redis.new
    end

    context 'with a set that has three elements' do
      before do
        @client.sadd("key1", "a")
        @client.sadd("key1", "b")
        @client.sadd("key1", "c")
      end

      context 'when called without the optional number parameter' do
        it 'is a random element from the set' do
          random_element = @client.srandmember("key1")

          expect(['a', 'b', 'c'].include?(random_element)).to be true
        end
      end

      context 'when called with the optional number parameter of 1' do
        it 'is an array of one random element from the set' do
          random_elements = @client.srandmember("key1", 1)

          expect([['a'], ['b'], ['c']].include?(random_elements)).to be true
        end
      end

      context 'when called with the optional number parameter of 2' do
        it 'is an array of two unique, random elements from the set' do
          random_elements = @client.srandmember("key1", 2)

          expect(random_elements.count).to eq(2)
          expect(random_elements.uniq.count).to eq(2)
          random_elements.all? do |element|
            expect(['a', 'b', 'c'].include?(element)).to be true
          end
        end
      end

      context 'when called with an optional parameter of -100' do
        it 'is an array of 100 random elements from the set, some of which are repeated' do
          random_elements = @client.srandmember("key1", -100)

          expect(random_elements.count).to eq(100)
          expect(random_elements.uniq.count).to be <= 3
          random_elements.all? do |element|
            expect(['a', 'b', 'c'].include?(element)).to be true
          end
        end
      end

      context 'when called with an optional parameter of 100' do
        it 'is an array of all of the elements from the set, none of which are repeated' do
          random_elements = @client.srandmember("key1", 100)

          expect(random_elements.count).to eq(3)
          expect(random_elements.uniq.count).to eq(3)
          expect(random_elements).to match_array(['a', 'b', 'c'])
        end
      end
    end

    context 'with an empty set' do
      before { @client.del("key1") }

      it 'is nil without the extra parameter' do
        expect(@client.srandmember("key1")).to be_nil
      end

      it 'is an empty array with an extra parameter' do
        expect(@client.srandmember("key1", 1)).to eq([])
      end
    end

    describe "#sscan" do
      it 'with no arguments and few items, returns all items' do
        @client.sadd('set', ['name', 'Jack', 'age', '33'])
        result = @client.sscan('set', 0)

        expect(result[0]).to eq('0')
        expect(result[1]).to eq(['name', 'Jack', 'age', '33'])
      end

      it 'with a count should return that number of members or more' do
        @client.sadd('set', ['a', '1', 'b', '2', 'c', '3', 'd', '4', 'e', '5', 'f', '6', 'g', '7'])
        result = @client.sscan('set', 0, count: 3)
        expect(result[0]).to eq('3')
        expect(result[1]).to eq([ 'a', '1', 'b'])
      end

      it 'returns items starting at the provided cursor' do
        @client.sadd('set', ['a', '1', 'b', '2', 'c', '3', 'd', '4', 'e', '5', 'f', '6', 'g', '7'])
        result = @client.sscan('set', 2, count: 3)
        expect(result[0]).to eq('5')
        expect(result[1]).to eq(['b', '2', 'c'])
      end

      it 'with match, returns items matching the given pattern' do
        @client.sadd('set', ['aa', '1', 'b', '2', 'cc', '3', 'd', '4', 'ee', '5', 'f', '6', 'gg', '7'])
        result = @client.sscan('set', 2, count: 7, match: '??')
        expect(result[0]).to eq('9')
        expect(result[1]).to eq(['cc','ee'])
      end

      it 'returns an empty result if the key is not found' do
        result = @client.sscan('set', 0)

        expect(result[0]).to eq('0')
        expect(result[1]).to eq([])
      end
    end
  end
end
