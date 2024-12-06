# encoding: UTF-8

require 'spec_helper'

module FakeRedis
  describe "StringsMethods" do

    before(:each) do
      @client = Redis.new
    end

    it "should append a value to key" do
      @client.set("key1", "Hello")
      @client.append("key1", " World")

      expect(@client.get("key1")).to eq("Hello World")
    end

    it "should decrement the integer value of a key by one" do
      @client.set("counter", "1")
      @client.decr("counter")

      expect(@client.get("counter")).to eq("0")
    end

    it "should decrement the integer value of a key by the given number" do
      @client.set("counter", "10")
      @client.decrby("counter", "5")

      expect(@client.get("counter")).to eq("5")
    end

    it "should get the value of a key" do
      expect(@client.get("key2")).to eq(nil)
    end

    it "should returns the bit value at offset in the string value stored at key" do
      @client.set("key1", "a")

      expect(@client.getbit("key1", 1)).to eq(1)
      expect(@client.getbit("key1", 2)).to eq(1)
      expect(@client.getbit("key1", 3)).to eq(0)
      expect(@client.getbit("key1", 4)).to eq(0)
      expect(@client.getbit("key1", 5)).to eq(0)
      expect(@client.getbit("key1", 6)).to eq(0)
      expect(@client.getbit("key1", 7)).to eq(1)
    end

    it "should allow direct bit manipulation even if the string isn't set" do
      @client.setbit("key1", 10, 1)
      expect(@client.getbit("key1", 10)).to eq(1)
    end

    context 'when a bit is previously set to 0' do
      before { @client.setbit("key1", 10, 0) }

      it 'setting it to 1 returns 0' do
        expect(@client.setbit("key1", 10, 1)).to eql 0
      end

      it 'setting it to 0 returns 0' do
        expect(@client.setbit("key1", 10, 0)).to eql 0
      end
    end

    context 'when a bit is previously set to 1' do
      before { @client.setbit("key1", 10, 1) }

      it 'setting it to 0 returns 1' do
        expect(@client.setbit("key1", 10, 0)).to eql 1
      end

      it 'setting it to 1 returns 1' do
        expect(@client.setbit("key1", 10, 1)).to eql 1
      end
    end

    it "should get a substring of the string stored at a key" do
      @client.set("key1", "This a message")

      expect(@client.getrange("key1", 0, 3)).to eq("This")
      expect(@client.substr("key1", 0, 3)).to eq("This")
    end

    it "should set the string value of a key and return its old value" do
      @client.set("key1","value1")

      expect(@client.getset("key1", "value2")).to eq("value1")
      expect(@client.get("key1")).to eq("value2")
    end

    it "should return nil for #getset if the key does not exist when setting" do
      expect(@client.getset("key1", "value1")).to eq(nil)
      expect(@client.get("key1")).to eq("value1")
    end

    it "should increment the integer value of a key by one" do
      @client.set("counter", "1")
      expect(@client.incr("counter")).to eq(2)

      expect(@client.get("counter")).to eq("2")
    end

    it "should not change the expire value of the key during incr" do
      @client.set("counter", "1")
      expect(@client.expire("counter", 600)).to be true
      expect(@client.ttl("counter")).to eq(600)
      expect(@client.incr("counter")).to eq(2)
      expect(@client.ttl("counter")).to eq(600)
    end

    it "should decrement the integer value of a key by one" do
      @client.set("counter", "1")
      expect(@client.decr("counter")).to eq(0)

      expect(@client.get("counter")).to eq("0")
    end

    it "should not change the expire value of the key during decr" do
      @client.set("counter", "2")
      expect(@client.expire("counter", 600)).to be true
      expect(@client.ttl("counter")).to eq(600)
      expect(@client.decr("counter")).to eq(1)
      expect(@client.ttl("counter")).to eq(600)
    end

    it "should increment the integer value of a key by the given number" do
      @client.set("counter", "10")
      expect(@client.incrby("counter", "5")).to eq(15)
      expect(@client.incrby("counter", 2)).to eq(17)
      expect(@client.get("counter")).to eq("17")
    end

    it "should increment the float value of a key by the given number" do
      @client.set("counter", 10.0)
      expect(@client.incrbyfloat("counter", 2.1)).to eq(12.1)
      expect(@client.get("counter")).to eq("12.1")
    end

    it "should not change the expire value of the key during incrby" do
      @client.set("counter", "1")
      expect(@client.expire("counter", 600)).to be true
      expect(@client.ttl("counter")).to eq(600)
      expect(@client.incrby("counter", "5")).to eq(6)
      expect(@client.ttl("counter")).to eq(600)
    end

    it "should decrement the integer value of a key by the given number" do
      @client.set("counter", "10")
      expect(@client.decrby("counter", "5")).to eq(5)
      expect(@client.decrby("counter", 2)).to eq(3)
      expect(@client.get("counter")).to eq("3")
    end

    it "should not change the expire value of the key during decrby" do
      @client.set("counter", "8")
      expect(@client.expire("counter", 600)).to be true
      expect(@client.ttl("counter")).to eq(600)
      expect(@client.decrby("counter", "3")).to eq(5)
      expect(@client.ttl("counter")).to eq(600)
    end

    it "should get the values of all the given keys" do
      @client.set("key1", "value1")
      @client.set("key2", "value2")
      @client.set("key3", "value3")

      expect(@client.mget("key1", "key2", "key3")).to eq(["value1", "value2", "value3"])
      expect(@client.mget(["key1", "key2", "key3"])).to eq(["value1", "value2", "value3"])
    end

    it "returns nil for non existent keys" do
      @client.set("key1", "value1")
      @client.set("key3", "value3")

      expect(@client.mget("key1", "key2", "key3", "key4")).to eq(["value1", nil, "value3", nil])
      expect(@client.mget(["key1", "key2", "key3", "key4"])).to eq(["value1", nil, "value3", nil])
    end

    it 'raises an argument error when not passed any fields' do
      @client.set("key3", "value3")

      expect { @client.mget }.to raise_error(Redis::CommandError)
    end

    it "should set multiple keys to multiple values" do
      @client.mset(:key1, "value1", :key2, "value2")

      expect(@client.get("key1")).to eq("value1")
      expect(@client.get("key2")).to eq("value2")
    end

    it "should raise error if command arguments count is wrong" do
      expect { @client.mset }.to raise_error(Redis::CommandError, "ERR wrong number of arguments for 'mset' command")
      expect { @client.mset(:key1) }.to raise_error(Redis::CommandError, "ERR wrong number of arguments for 'mset' command")
      expect { @client.mset(:key1, "value", :key2) }.to raise_error(Redis::CommandError, "ERR wrong number of arguments for MSET")

      expect(@client.get("key1")).to be_nil
      expect(@client.get("key2")).to be_nil
    end

    it "should set multiple keys to multiple values, only if none of the keys exist" do
      expect(@client.msetnx(:key1, "value1", :key2, "value2")).to eq(true)
      expect(@client.msetnx(:key1, "value3", :key2, "value4")).to eq(false)

      expect(@client.get("key1")).to eq("value1")
      expect(@client.get("key2")).to eq("value2")
    end

    it "should set multiple keys to multiple values with a hash" do
      @client.mapped_mset(:key1 => "value1", :key2 => "value2")

      expect(@client.get("key1")).to eq("value1")
      expect(@client.get("key2")).to eq("value2")
    end

    it "should set multiple keys to multiple values with a hash, only if none of the keys exist" do
      expect(@client.mapped_msetnx(:key1 => "value1", :key2 => "value2")).to eq(true)
      expect(@client.mapped_msetnx(:key1 => "value3", :key2 => "value4")).to eq(false)

      expect(@client.get("key1")).to eq("value1")
      expect(@client.get("key2")).to eq("value2")
    end

    it "should set the string value of a key" do
      @client.set("key1", "1")

      expect(@client.get("key1")).to eq("1")
    end

    it "should sets or clears the bit at offset in the string value stored at key" do
      @client.set("key1", "abc")
      @client.setbit("key1", 11, 1)

      expect(@client.get("key1")).to eq("arc")
    end

    it "should set the value and expiration of a key" do
      @client.setex("key1", 30, "value1")

      expect(@client.get("key1")).to eq("value1")
      expect(@client.ttl("key1")).to eq(30)
    end

    it "should set the value of a key, only if the key does not exist" do
      expect(@client.setnx("key1", "test value")).to eq(true)
      expect(@client.setnx("key1", "new value")).to eq(false)
      @client.setnx("key2", "another value")

      expect(@client.get("key1")).to eq("test value")
      expect(@client.get("key2")).to eq("another value")
    end

    it "should overwrite part of a string at key starting at the specified offset" do
      @client.set("key1", "Hello World")
      @client.setrange("key1", 6, "Redis")

      expect(@client.get("key1")).to eq("Hello Redis")
    end

    it "should get the length of the value stored in a key" do
      @client.set("key1", "abc")

      expect(@client.strlen("key1")).to eq(3)
    end

    it "should return 0 bits when there's no key" do
      expect(@client.bitcount("key1")).to eq(0)
    end

    it "should count the number of bits of a string" do
      @client.set("key1", "foobar")
      expect(@client.bitcount("key1")).to eq(26)
    end

    it "should count correctly with UTF-8 strings" do
      @client.set("key1", '判')
      expect(@client.bitcount("key1")).to eq(10)
    end

    it "should count the number of bits of a string given a range" do
      @client.set("key1", "foobar")

      expect(@client.bitcount("key1", 0, 0)).to eq(4)
      expect(@client.bitcount("key1", 1, 1)).to eq(6)
      expect(@client.bitcount("key1", 0, 1)).to eq(10)
    end

    describe "#bitpos" do
      it "should return -1 when there's no key" do
        expect(@client.bitpos("key", 0)).to eq(-1)
      end

      it "should return -1 for empty key" do
        @client.set("key", "")
        expect(@client.bitpos("key", 0)).to eq(-1)
      end

      it "should return position of the bit in a string" do
        @client.set("key", "foobar") # 01100110 01101111 01101111
        expect(@client.bitpos("key", 1)).to eq(1)
      end

      it "should return position of the bit correctly with UTF-8 strings" do
        @client.set("key", "判") # 11100101 10001000 10100100
        expect(@client.bitpos("key", 0)).to eq(3)
      end

      it "should return position of the bit in a string given a range" do
        @client.set("key", "foobar")

        expect(@client.bitpos("key", 1, 0)).to eq(1)
        expect(@client.bitpos("key", 1, 1, 2)).to eq(9)
        expect(@client.bitpos("key", 0, 1, -1)).to eq(8)
      end
    end
  end
end
