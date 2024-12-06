require 'spec_helper'

module FakeRedis
  describe "ServerMethods" do

    before(:each) do
      @client = Redis.new
    end

    it "should return the number of keys in the selected database" do
      @client.set("key1", "1")
      @client.set("key2", "2")
      @client.set("key2", "two")

      expect(@client.dbsize).to eq(2)
    end

    it "should get information and statistics about the server" do
      expect(@client.info.key?("redis_version")).to eq(true)
    end

    it "should handle non-existent methods" do
      expect { @client.idontexist }.to raise_error(Redis::CommandError, "ERR unknown command 'idontexist'")
    end

    describe "multiple databases" do
      it "should default to database 0" do
        expect(@client.inspect).to match(%r#/0>$#)
      end

      it "should select another database" do
        @client.select(1)
        expect(@client.inspect).to match(%r#/1>$#)
      end

      it "should store keys separately in each database" do
        expect(@client.select(0)).to eq("OK")
        @client.set("key1", "1")
        @client.set("key2", "2")

        @client.select(1)
        @client.set("key3", "3")
        @client.set("key4", "4")
        @client.set("key5", "5")

        @client.select(0)
        expect(@client.dbsize).to eq(2)
        expect(@client.exists("key1")).to be true
        expect(@client.exists("key3")).to be false

        @client.select(1)
        expect(@client.dbsize).to eq(3)
        expect(@client.exists("key4")).to be true
        expect(@client.exists("key2")).to be false

        @client.flushall
        expect(@client.dbsize).to eq(0)

        @client.select(0)
        expect(@client.dbsize).to eq(0)
      end

      it "should flush a database" do
        @client.select(0)
        @client.set("key1", "1")
        @client.set("key2", "2")
        expect(@client.dbsize).to eq(2)

        @client.select(1)
        @client.set("key3", "3")
        @client.set("key4", "4")
        expect(@client.dbsize).to eq(2)

        expect(@client.flushdb).to eq("OK")

        expect(@client.dbsize).to eq(0)
        @client.select(0)
        expect(@client.dbsize).to eq(2)
      end

      it "should flush all databases" do
        @client.select(0)
        @client.set("key3", "3")
        @client.set("key4", "4")
        expect(@client.dbsize).to eq(2)

        @client.select(1)
        @client.set("key3", "3")
        @client.set("key4", "4")
        expect(@client.dbsize).to eq(2)

        expect(@client.flushall).to eq("OK")

        expect(@client.dbsize).to eq(0)
        @client.select(0)
        expect(@client.dbsize).to eq(0)
      end
    end
  end

  describe 'custom options' do
    describe 'version' do
      it 'reports default Redis version when not provided' do
        client = Redis.new
        expect(client.info['redis_version']).to eq Redis::Connection::DEFAULT_REDIS_VERSION
      end

      it 'creates with and reports properly' do
        client = Redis.new(version: '3.3.0')
        expect(client.info['redis_version']).to eq '3.3.0'
      end
    end
  end
end
