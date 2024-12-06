require 'spec_helper'

module FakeRedis
  describe "KeysMethods" do

    before(:each) do
      @client = Redis.new
    end

    [:del, :unlink].each do |command|
      it "should #{command} a key" do
        @client.set("key1", "1")
        @client.set("key2", "2")
        @client.public_send(command, "key1", "key2")

        expect(@client.get("key1")).to eq(nil)
      end

      it "should #{command} multiple keys" do
        @client.set("key1", "1")
        @client.set("key2", "2")
        @client.public_send(command, ["key1", "key2"])

        expect(@client.get("key1")).to eq(nil)
        expect(@client.get("key2")).to eq(nil)
      end

      it "should return the number of '#{command}'ed keys" do
        @client.set("key1", "1")
        expect(@client.public_send(command, ["key1", "key2"])).to eq(1)
      end

      it "should error '#{command}'ing no keys" do
        expect { @client.public_send(command) }.to raise_error(Redis::CommandError, "ERR wrong number of arguments for '#{command}' command")
        expect { @client.public_send(command, []) }.to raise_error(Redis::CommandError, "ERR wrong number of arguments for '#{command}' command")
      end
    end

    it "should return true when setnx keys that don't exist" do
      expect(@client.setnx("key1", "1")).to eq(true)
    end

    it "should return false when setnx keys exist" do
      @client.set("key1", "1")
      expect(@client.setnx("key1", "1")).to eq(false)
    end

    it "should return true when setting expires on keys that exist" do
      @client.set("key1", "1")
      expect(@client.expire("key1", 1)).to eq(true)
    end

    it "should return true when setting pexpires on keys that exist" do
      @client.set("key1", "1")
      expect(@client.pexpire("key1", 1)).to eq(true)
    end

    it "should return false when attempting to set expires on a key that does not exist" do
      expect(@client.expire("key1", 1)).to eq(false)
    end

    it "should return false when attempting to set pexpires on a key that does not exist" do
      expect(@client.pexpire("key1", 1)).to eq(false)
    end

    it "should determine if a key exists" do
      @client.set("key1", "1")

      expect(@client.exists("key1")).to eq(true)
      expect(@client.exists("key2")).to eq(false)
    end

    it "should set a key's time to live in seconds" do
      @client.set("key1", "1")
      @client.expire("key1", 1)

      expect(@client.ttl("key1")).to eq(1)
    end

    it "should set a key's time to live in miliseconds" do
      allow(Time).to receive(:now).and_return(1000)
      @client.set("key1", "1")
      @client.pexpire("key1", 2200)
      expect(@client.pttl("key1")).to be_within(0.1).of(2200)
      allow(Time).to receive(:now).and_call_original
    end

    it "should set the expiration for a key as a UNIX timestamp" do
      @client.set("key1", "1")
      @client.expireat("key1", Time.now.to_i + 2)

      expect(@client.ttl("key1")).to eq(2)
    end

    it "should not have an expiration after re-set" do
      @client.set("key1", "1")
      @client.expireat("key1", Time.now.to_i + 2)
      @client.set("key1", "1")

      expect(@client.ttl("key1")).to eq(-1)
    end

    it "should not have a ttl if expired (and thus key does not exist)" do
      @client.set("key1", "1")
      @client.expireat("key1", Time.now.to_i)

      expect(@client.ttl("key1")).to eq(-2)
    end

    it "should not find a key if expired" do
      @client.set("key1", "1")
      @client.expireat("key1", Time.now.to_i)

      expect(@client.get("key1")).to be_nil
    end

    it "should not find multiple keys if expired" do
      @client.set("key1", "1")
      @client.set("key2", "2")
      @client.expireat("key1", Time.now.to_i)

      expect(@client.mget("key1", "key2")).to eq([nil, "2"])
    end

    it "should only find keys that aren't expired" do
      @client.set("key1", "1")
      @client.set("key2", "2")
      @client.expireat("key1", Time.now.to_i)

      expect(@client.keys).to eq(["key2"])
    end

    it "should not exist if expired" do
      @client.set("key1", "1")
      @client.expireat("key1", Time.now.to_i)

      expect(@client.exists("key1")).to be false
    end

    it "should get integer and string keys" do
      @client.set("key1", "1")
      @client.set(2, "2")

      expect(@client.mget("key1", 2)).to eq(["1", "2"])
    end

    it "should find all keys matching the given pattern" do
      @client.set("key:a", "1")
      @client.set("key:b", "2")
      @client.set("key:c", "3")
      @client.set("akeyd", "4")
      @client.set("key1", "5")

      @client.mset("database", 1, "above", 2, "suitability", 3, "able", 4)

      expect(@client.keys("key:*")).to match_array(["key:a", "key:b", "key:c"])
      expect(@client.keys("ab*")).to match_array(["above", "able"])
    end

    it "should remove the expiration from a key" do
      @client.set("key1", "1")
      @client.expireat("key1", Time.now.to_i + 1)
      expect(@client.persist("key1")).to eq(true)
      expect(@client.persist("key1")).to eq(false)

      expect(@client.ttl("key1")).to eq(-1)
    end

    it "should return a random key from the keyspace" do
      @client.set("key1", "1")
      @client.set("key2", "2")

      expect(["key1", "key2"].include?(@client.randomkey)).to eq(true)
    end

    it "should rename a key" do
      @client.set("key1", "2")
      @client.rename("key1", "key2")

      expect(@client.get("key1")).to eq(nil)
      expect(@client.get("key2")).to eq("2")
    end

    it "should rename a key, only if new key does not exist" do
      @client.set("key1", "1")
      @client.set("key2", "2")
      @client.set("key3", "3")
      @client.renamenx("key1", "key2")
      @client.renamenx("key3", "key4")

      expect(@client.get("key1")).to eq("1")
      expect(@client.get("key2")).to eq("2")
      expect(@client.get("key3")).to eq(nil)
      expect(@client.get("key4")).to eq("3")
    end

    it "should determine the type stored at key" do
      # Non-existing key
      expect(@client.type("key0")).to eq("none")

      # String
      @client.set("key1", "1")
      expect(@client.type("key1")).to eq("string")

      # List
      @client.lpush("key2", "1")
      expect(@client.type("key2")).to eq("list")

      # Set
      @client.sadd("key3", "1")
      expect(@client.type("key3")).to eq("set")

      # Sorted Set
      @client.zadd("key4", 1.0, "1")
      expect(@client.type("key4")).to eq("zset")

      # Hash
      @client.hset("key5", "a", "1")
      expect(@client.type("key5")).to eq("hash")
    end

    it "should convert the value into a string before storing" do
      @client.set("key1", 1)
      expect(@client.get("key1")).to eq("1")

      @client.setex("key2", 30, 1)
      expect(@client.get("key2")).to eq("1")

      @client.getset("key3", 1)
      expect(@client.get("key3")).to eq("1")
    end

    it "should return 'OK' for the setex command" do
      expect(@client.setex("key4", 30, 1)).to eq("OK")
    end

    it "should convert the key into a string before storing" do
      @client.set(123, "foo")
      expect(@client.keys).to include("123")
      expect(@client.get("123")).to eq("foo")

      @client.setex(456, 30, "foo")
      expect(@client.keys).to include("456")
      expect(@client.get("456")).to eq("foo")

      @client.getset(789, "foo")
      expect(@client.keys).to include("789")
      expect(@client.get("789")).to eq("foo")
    end

    it "should only operate against keys containing string values" do
      @client.sadd("key1", "one")
      expect { @client.get("key1") }.to raise_error(Redis::CommandError, "WRONGTYPE Operation against a key holding the wrong kind of value")
      expect { @client.getset("key1", 1) }.to raise_error(Redis::CommandError, "WRONGTYPE Operation against a key holding the wrong kind of value")

      @client.hset("key2", "one", "two")
      expect { @client.get("key2") }.to raise_error(Redis::CommandError, "WRONGTYPE Operation against a key holding the wrong kind of value")
      expect { @client.getset("key2", 1) }.to raise_error(Redis::CommandError, "WRONGTYPE Operation against a key holding the wrong kind of value")
    end

    it "should move a key from one database to another successfully" do
      @client.select(0)
      @client.set("key1", "1")

      expect(@client.move("key1", 1)).to eq(true)

      @client.select(0)
      expect(@client.get("key1")).to be_nil

      @client.select(1)
      expect(@client.get("key1")).to eq("1")
    end

    it "should fail to move a key that does not exist in the source database" do
      @client.select(0)
      expect(@client.get("key1")).to be_nil

      expect(@client.move("key1", 1)).to eq(false)

      @client.select(0)
      expect(@client.get("key1")).to be_nil

      @client.select(1)
      expect(@client.get("key1")).to be_nil
    end

    it "should fail to move a key that exists in the destination database" do
      @client.select(0)
      @client.set("key1", "1")

      @client.select(1)
      @client.set("key1", "2")

      @client.select(0)
      expect(@client.move("key1", 1)).to eq(false)

      @client.select(0)
      expect(@client.get("key1")).to eq("1")

      @client.select(1)
      expect(@client.get("key1")).to eq("2")
    end

    it "should fail to move a key to the same database" do
      @client.select(0)
      @client.set("key1", "1")

      expect { @client.move("key1", 0) }.to raise_error(Redis::CommandError, "ERR source and destination objects are the same")

      @client.select(0)
      expect(@client.get("key1")).to eq("1")
    end

    it "should scan all keys in the database" do
      100.times do |x|
        @client.set("key#{x}", "#{x}")
      end

      cursor = 0
      all_keys = []
      loop {
        cursor, keys = @client.scan(cursor)
        all_keys += keys
        break if cursor == "0"
      }

      expect(all_keys.uniq.size).to eq(100)
      expect(all_keys[0]).to match(/key\d+/)
    end

    it "should match keys to a pattern when scanning" do
      50.times do |x|
        @client.set("key#{x}", "#{x}")
      end

      @client.set("miss_me", 1)
      @client.set("pass_me", 2)

      cursor = 0
      all_keys = []
      loop {
        cursor, keys = @client.scan(cursor, :match => "key*")
        all_keys += keys
        break if cursor == "0"
      }

      expect(all_keys.uniq.size).to eq(50)
    end

    it "should specify doing more work when scanning" do
      100.times do |x|
        @client.set("key#{x}", "#{x}")
      end

      cursor, all_keys = @client.scan(cursor, :count => 100)

      expect(cursor).to eq("0")
      expect(all_keys.uniq.size).to eq(100)
    end

    context "with extended options" do
      it "uses ex option to set the expire time, in seconds" do
        ttl = 7

        expect(@client.set("key1", "1", { :ex => ttl })).to eq("OK")
        expect(@client.ttl("key1")).to eq(ttl)
      end

      it "uses px option to set the expire time, in miliseconds" do
        ttl = 7000

        expect(@client.set("key1", "1", { :px => ttl })).to eq("OK")
        expect(@client.ttl("key1")).to eq(ttl / 1000)
      end

      # Note that the redis-rb implementation will always give PX last.
      # Redis seems to process each expiration option and the last one wins.
      it "prefers the finer-grained PX expiration option over EX" do
        ttl_px = 6000
        ttl_ex = 10

        @client.set("key1", "1", { :px => ttl_px, :ex => ttl_ex })
        expect(@client.ttl("key1")).to eq(ttl_px / 1000)

        @client.set("key1", "1", { :ex => ttl_ex, :px => ttl_px })
        expect(@client.ttl("key1")).to eq(ttl_px / 1000)
      end

      it "uses nx option to only set the key if it does not already exist" do
        expect(@client.set("key1", "1", { :nx => true })).to eq(true)
        expect(@client.set("key1", "2", { :nx => true })).to eq(false)

        expect(@client.get("key1")).to eq("1")
      end

      it "uses xx option to only set the key if it already exists" do
        expect(@client.set("key2", "1", { :xx => true })).to eq(false)
        @client.set("key2", "2")
        expect(@client.set("key2", "1", { :xx => true })).to eq(true)

        expect(@client.get("key2")).to eq("1")
      end

      it "does not set the key if both xx and nx option are specified" do
        expect(@client.set("key2", "1", { :nx => true, :xx => true })).to eq(false)
        expect(@client.get("key2")).to be_nil
      end
    end

    describe "#dump" do
      it "returns nil for unknown key" do
        expect(@client.exists("key1")).to be false
        expect(@client.dump("key1")).to be nil
      end

      it "dumps a single known key successfully" do
        @client.set("key1", "zomgwtf")

        value = @client.dump("key1")
        expect(value).not_to eq nil
        expect(value).to be_a_kind_of(String)
      end

      it "errors with more than one argument" do
        expect { @client.dump("key1", "key2") }.to raise_error(ArgumentError)
      end
    end

    describe "#restore" do
      it "errors with a missing payload" do
        expect do
          @client.restore("key1", 0, nil)
        end.to raise_error(Redis::CommandError, "ERR DUMP payload version or checksum are wrong")
      end

      it "errors with an invalid payload" do
        expect do
          @client.restore("key1", 0, "zomgwtf not valid")
        end.to raise_error(Redis::CommandError, "ERR DUMP payload version or checksum are wrong")
      end

      describe "with a dumped value" do
        before do
          @client.set("key1", "original value")
          @dumped_value = @client.dump("key1")

          @client.del("key1")
          expect(@client.exists("key1")).to be false
        end

        it "restores to a new key successfully" do
          response = @client.restore("key1", 0, @dumped_value)
          expect(response).to eq "OK"
        end

        it "errors trying to restore to an existing key" do
          @client.set("key1", "something else")

          expect do
            @client.restore("key1", 0, @dumped_value)
          end.to raise_error(Redis::CommandError, "ERR Target key name is busy.")
        end

        it "restores successfully with a given expire time" do
          @client.restore("key2", 2000, @dumped_value)

          expect(@client.ttl("key2")).to eq 2
        end

        it "restores a list successfully" do
          @client.lpush("key1", "val1")
          @client.lpush("key1", "val2")

          expect(@client.type("key1")).to eq "list"

          dumped_value = @client.dump("key1")

          response = @client.restore("key2", 0, dumped_value)
          expect(response).to eq "OK"

          expect(@client.type("key2")).to eq "list"
        end

        it "restores a set successfully" do
          @client.sadd("key1", "val1")
          @client.sadd("key1", "val2")

          expect(@client.type("key1")).to eq "set"

          dumped_value = @client.dump("key1")

          response = @client.restore("key2", 0, dumped_value)
          expect(response).to eq "OK"

          expect(@client.type("key2")).to eq "set"
        end
      end
    end

    describe "#psetex" do
      it "should set a key's time to live in milliseconds" do
        allow(Time).to receive(:now).and_return(1000)
        @client.psetex("key", 2200, "value")
        expect(@client.pttl("key")).to be_within(0.1).of(2200)
      end

      it "should return 'OK'" do
        expect(@client.psetex("key", 1000, "value")).to eq("OK")
      end
    end
  end
end

