require 'spec_helper'

module FakeRedis
  describe "#sort" do
    before(:each) do
      @client = Redis.new

      @client.set('fake-redis-test:values_1', 'a')
      @client.set('fake-redis-test:values_2', 'b')

      @client.set('fake-redis-test:weight_1', '2')
      @client.set('fake-redis-test:weight_2', '1')

      @client.hset('fake-redis-test:hash_1', 'key', 'x')
      @client.hset('fake-redis-test:hash_2', 'key', 'y')
    end

    context "WRONGTYPE Operation" do
      it "should not allow #sort on Strings" do
        @client.set("key1", "Hello")
        expect {
          @client.sort("key1")
        }.to raise_error(Redis::CommandError)
      end

      it "should not allow #sort on Hashes" do
        @client.hset("key1", "k1", "val1")
        @client.hset("key1", "k2", "val2")
        expect {
          @client.sort("key1")
        }.to raise_error(Redis::CommandError)
      end
    end

    context "none" do
      it "should return empty array" do
        expect(@client.sort("key")).to eq []
      end
    end

    context "list" do
      before do
        @key = "fake-redis-test:list_sort"

        @client.rpush(@key, '1')
        @client.rpush(@key, '2')
      end

      it_should_behave_like "a sortable"
    end

    context "set" do
      before do
        @key = "fake-redis-test:set_sort"

        @client.sadd(@key, '1')
        @client.sadd(@key, '2')
      end

      it_should_behave_like "a sortable"
    end

    context "zset" do
      before do
        @key = "fake-redis-test:zset_sort"

        @client.zadd(@key, 100, '1')
        @client.zadd(@key, 99, '2')
      end

      it_should_behave_like "a sortable"
    end
  end
end
