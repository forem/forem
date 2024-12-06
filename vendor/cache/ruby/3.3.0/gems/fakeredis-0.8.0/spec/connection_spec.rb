require 'spec_helper'

module FakeRedis
  describe "ConnectionMethods" do

    before(:each) do
      @client = Redis.new
    end

  if fakeredis?
    it "should authenticate to the server" do
      expect(@client.auth("pass")).to eq("OK")
    end

    it "should re-use the same instance with the same host & port" do
      @client1 = Redis.new(:host => "localhost", :port => 1234)
      @client2 = Redis.new(:host => "localhost", :port => 1234)
      @client3 = Redis.new(:host => "localhost", :port => 5678)

      @client1.set("key1", "1")
      expect(@client2.get("key1")).to eq("1")
      expect(@client3.get("key1")).to be_nil

      @client2.set("key2", "2")
      expect(@client1.get("key2")).to eq("2")
      expect(@client3.get("key2")).to be_nil

      @client3.set("key3", "3")
      expect(@client1.get("key3")).to be_nil
      expect(@client2.get("key3")).to be_nil

      expect(@client1.dbsize).to eq(2)
      expect(@client2.dbsize).to eq(2)
      expect(@client3.dbsize).to eq(1)
    end

    it "should connect to a specific database" do
      @client1 = Redis.new(:host => "localhost", :port => 1234, :db => 0)
      @client1.set("key1", "1")
      @client1.select(0)
      expect(@client1.get("key1")).to eq("1")

      @client2 = Redis.new(:host => "localhost", :port => 1234, :db => 1)
      @client2.set("key1", "1")
      @client2.select(1)
      expect(@client2.get("key1")).to eq("1")
    end

    it "should not error with shutdown" do
      expect { @client.shutdown }.not_to raise_error
    end

    it "should not error with quit" do
      expect { @client.quit }.not_to raise_error
    end
  end

    it "should handle multiple clients using the same db instance" do
      @client1 = Redis.new(:host => "localhost", :port => 6379, :db => 1)
      @client2 = Redis.new(:host => "localhost", :port => 6379, :db => 2)

      @client1.set("key1", "one")
      expect(@client1.get("key1")).to eq("one")

      @client2.set("key2", "two")
      expect(@client2.get("key2")).to eq("two")

      expect(@client1.get("key1")).to eq("one")
    end

    it "should not error with a disconnected client" do
      @client1 = Redis.new
      @client1.close
      expect(@client1.get("key1")).to be_nil
    end

    it "should echo the given string" do
      expect(@client.echo("something")).to eq("something")
    end

    it "should ping the server" do
      expect(@client.ping).to eq("PONG")
    end
  end
end
