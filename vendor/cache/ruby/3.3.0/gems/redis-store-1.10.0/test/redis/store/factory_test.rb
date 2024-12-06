require 'test_helper'
require 'json'

describe "Redis::Store::Factory" do
  describe ".create" do
    describe "when not given any arguments" do
      it "instantiates Redis::Store" do
        store = Redis::Store::Factory.create
        _(store).must_be_kind_of(Redis::Store)
        # `redis.rb` use different default host values in v4 & v5
        _(store.to_s).must_match(%r{^Redis Client connected to (127.0.0.1|localhost):6379 against DB 0$})
      end
    end

    describe "when given a Hash" do
      it "uses specified host" do
        store = Redis::Store::Factory.create :host => "localhost"
        _(store.to_s).must_equal("Redis Client connected to localhost:6379 against DB 0")
      end

      it "uses specified port" do
        store = Redis::Store::Factory.create :host => "localhost", :port => 6380
        _(store.to_s).must_equal("Redis Client connected to localhost:6380 against DB 0")
      end

      it "uses specified scheme" do
        store = Redis::Store::Factory.create :scheme => "rediss"
        client = store.instance_variable_get(:@client)
        # `redis-client` does NOT have `scheme`
        client.respond_to?(:scheme) && _(client.scheme).must_equal('rediss')
      end

      it "uses specified path" do
        store = Redis::Store::Factory.create :path => "/var/run/redis.sock"
        _(store.to_s).must_equal("Redis Client connected to /var/run/redis.sock against DB 0")
      end

      it "uses specified db" do
        store = Redis::Store::Factory.create :host => "localhost", :port => 6380, :db => 13
        _(store.to_s).must_equal("Redis Client connected to localhost:6380 against DB 13")
      end

      it "uses specified namespace" do
        store = Redis::Store::Factory.create :namespace => "theplaylist"
        # `redis.rb` use different default host values in v4 & v5
        _(store.to_s).must_match(%r{^Redis Client connected to (127.0.0.1|localhost):6379 against DB 0 with namespace theplaylist$})
      end

      it "uses specified key_prefix as namespace" do
        store = Redis::Store::Factory.create :key_prefix => "theplaylist"
        # `redis.rb` use different default host values in v4 & v5
        _(store.to_s).must_match(%r{^Redis Client connected to (127.0.0.1|localhost):6379 against DB 0 with namespace theplaylist$})
      end

      it "uses specified password" do
        store = Redis::Store::Factory.create :password => "secret"
        _(store.instance_variable_get(:@client).password).must_equal("secret")
      end

      it 'uses empty password' do
        store = Redis::Store::Factory.create :password => ''
        _(store.instance_variable_get(:@client).password).must_equal('')
      end

      it 'uses nil password' do
        store = Redis::Store::Factory.create :password => nil
        assert_nil(store.instance_variable_get(:@client).password)
      end

      it "disables serialization" do
        store = Redis::Store::Factory.create :serializer => nil
        _(store.instance_variable_get(:@serializer)).must_be_nil
        # `raw` would be removed when `redis-client` is used
        defined?(::RedisClient) || _(store.instance_variable_get(:@options)[:raw]).must_equal(true)
      end

      it "configures pluggable serialization backend" do
        store = Redis::Store::Factory.create :serializer => JSON
        _(store.instance_variable_get(:@serializer)).must_equal(JSON)
        # `raw` would be removed when `redis-client` is used
        defined?(::RedisClient) || _(store.instance_variable_get(:@options)[:raw]).must_equal(false)
      end

      describe "defaults" do
        it "defaults to localhost if no host specified" do
          store = Redis::Store::Factory.create
          # `redis.rb` use different default host values in v4 & v5
          _(store.instance_variable_get(:@client).host).must_match(%r{^127.0.0.1|localhost$})
        end

        it "defaults to 6379 if no port specified" do
          store = Redis::Store::Factory.create
          _(store.instance_variable_get(:@client).port).must_equal(6379)
        end

        it "defaults to redis:// if no scheme specified" do
          store = Redis::Store::Factory.create
          client = store.instance_variable_get(:@client)
          # `redis-client` does NOT have `scheme`
          client.respond_to?(:scheme) && _(client.scheme).must_equal('redis')
        end
      end

      describe 'with stdout disabled' do
        before do
          @original_stderr = $stderr
          @original_stdout = $stdout

          $stderr = Tempfile.new('stderr')
          $stdout = Tempfile.new('stdout')
        end

        it "disables marshalling and provides deprecation warning" do
          store = Redis::Store::Factory.create :marshalling => false
          _(store.instance_variable_get(:@serializer)).must_be_nil
          # `raw` would be removed when `redis-client` is used
          defined?(::RedisClient) || _(store.instance_variable_get(:@options)[:raw]).must_equal(true)
        end

        it "enables marshalling but provides warning to use :serializer instead" do
          store = Redis::Store::Factory.create :marshalling => true
          _(store.instance_variable_get(:@serializer)).must_equal(Marshal)
          # `raw` would be removed when `redis-client` is used
          defined?(::RedisClient) || _(store.instance_variable_get(:@options)[:raw]).must_equal(false)
        end

        after do
          $stderr = @original_stderr
          $stdout = @original_stdout
        end
      end

      it "should instantiate a Redis::DistributedStore store" do
        store = Redis::Store::Factory.create(
          { :host => "localhost", :port => 6379 },
          { :host => "localhost", :port => 6380 }
        )
        _(store).must_be_kind_of(Redis::DistributedStore)
        _(store.nodes.map { |node| node.to_s }).must_equal([
          "Redis Client connected to localhost:6379 against DB 0",
          "Redis Client connected to localhost:6380 against DB 0",
        ])
      end
    end

    describe "when given a String" do
      it "uses specified host" do
        store = Redis::Store::Factory.create "redis://127.0.0.1"
        _(store.to_s).must_equal("Redis Client connected to 127.0.0.1:6379 against DB 0")
      end

      it "uses specified port" do
        store = Redis::Store::Factory.create "redis://127.0.0.1:6380"
        _(store.to_s).must_equal("Redis Client connected to 127.0.0.1:6380 against DB 0")
      end

      it "uses specified scheme" do
        store = Redis::Store::Factory.create "rediss://127.0.0.1:6380"
        client = store.instance_variable_get(:@client)
        # `redis-client` does NOT have `scheme`
        client.respond_to?(:scheme) && _(client.scheme).must_equal('rediss')
      end

      it "correctly defaults to redis:// when relative scheme specified" do
        store = Redis::Store::Factory.create "//127.0.0.1:6379"
        client = store.instance_variable_get(:@client)
        # `redis-client` does NOT have `scheme`
        client.respond_to?(:scheme) && _(client.scheme).must_equal('redis')
      end

      it "uses specified path" do
        store = Redis::Store::Factory.create "unix:///var/run/redis.sock"
        _(store.to_s).must_equal("Redis Client connected to /var/run/redis.sock against DB 0")
      end

      it "uses specified db" do
        store = Redis::Store::Factory.create "redis://127.0.0.1:6380/13"
        _(store.to_s).must_equal("Redis Client connected to 127.0.0.1:6380 against DB 13")
      end

      it "uses specified namespace" do
        store = Redis::Store::Factory.create "redis://127.0.0.1:6379/0/theplaylist"
        _(store.to_s).must_equal("Redis Client connected to 127.0.0.1:6379 against DB 0 with namespace theplaylist")
      end

      it "uses specified via query namespace" do
        store = Redis::Store::Factory.create "redis://127.0.0.1:6379/0?namespace=theplaylist"
        _(store.to_s).must_equal("Redis Client connected to 127.0.0.1:6379 against DB 0 with namespace theplaylist")
      end

      it "uses specified namespace with path" do
        store = Redis::Store::Factory.create "unix:///var/run/redis.sock?db=2&namespace=theplaylist"
        _(store.to_s).must_equal("Redis Client connected to /var/run/redis.sock against DB 2 with namespace theplaylist")
      end

      it "uses specified password" do
        store = Redis::Store::Factory.create "redis://:secret@127.0.0.1:6379/0/theplaylist"
        _(store.instance_variable_get(:@client).password).must_equal("secret")
      end

      it 'uses specified password with special characters' do
        store = Redis::Store::Factory.create 'redis://:pwd%40123@127.0.0.1:6379/0/theplaylist'
        _(store.instance_variable_get(:@client).password).must_equal('pwd@123')
      end

      it 'uses empty password' do
        store = Redis::Store::Factory.create 'redis://:@127.0.0.1:6379/0/theplaylist'
        _(store.instance_variable_get(:@client).password).must_equal('')
      end

      it 'uses nil password' do
        store = Redis::Store::Factory.create 'redis://127.0.0.1:6379/0/theplaylist'
        assert_nil(store.instance_variable_get(:@client).password)
      end

      it "correctly uses specified ipv6 host" do
        store = Redis::Store::Factory.create "redis://[::1]:6380"
        _(store.to_s).must_equal("Redis Client connected to [::1]:6380 against DB 0")
        _(store.instance_variable_get('@options')[:host]).must_equal("::1")
      end

      it "instantiates Redis::DistributedStore" do
        store = Redis::Store::Factory.create "redis://127.0.0.1:6379", "redis://127.0.0.1:6380"
        _(store).must_be_kind_of(Redis::DistributedStore)
        _(store.nodes.map { |node| node.to_s }).must_equal([
          "Redis Client connected to 127.0.0.1:6379 against DB 0",
          "Redis Client connected to 127.0.0.1:6380 against DB 0",
        ])
      end
    end

    describe 'when given host Hash and options Hash' do
      it 'instantiates Redis::Store and merges options' do
        Redis::Store::Factory.create(
          { :host => '127.0.0.1', :port => '6379' },
          { :namespace => 'theplaylist' }
        )
      end

      it 'instantiates Redis::DistributedStore and merges options' do
        store = Redis::Store::Factory.create(
          { :host => '127.0.0.1', :port => '6379' },
          { :host => '127.0.0.1', :port => '6380' },
          { :namespace => 'theplaylist' }
        )
        _(store.nodes.map { |node| node.to_s }).must_equal([
          "Redis Client connected to 127.0.0.1:6379 against DB 0 with namespace theplaylist",
          "Redis Client connected to 127.0.0.1:6380 against DB 0 with namespace theplaylist"
        ])
      end
    end

    describe 'when given host String and options Hash' do
      it 'instantiates Redis::Store and merges options' do
        store = Redis::Store::Factory.create "redis://127.0.0.1", :namespace => 'theplaylist'
        _(store.to_s).must_equal("Redis Client connected to 127.0.0.1:6379 against DB 0 with namespace theplaylist")
      end

      it 'instantiates Redis::DistributedStore and merges options' do
        store = Redis::Store::Factory.create "redis://127.0.0.1:6379", "redis://127.0.0.1:6380", :namespace => 'theplaylist'
        _(store.nodes.map { |node| node.to_s }).must_equal([
          "Redis Client connected to 127.0.0.1:6379 against DB 0 with namespace theplaylist",
          "Redis Client connected to 127.0.0.1:6380 against DB 0 with namespace theplaylist",
        ])
      end

      it 'instantiates Redis::Store and sets namespace from String' do
        store = Redis::Store::Factory.create "redis://127.0.0.1:6379/0/theplaylist"
        _(store.to_s).must_equal("Redis Client connected to 127.0.0.1:6379 against DB 0 with namespace theplaylist")
      end
    end
  end
end
