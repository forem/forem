require 'test_helper'

describe "Redis::Store::Namespace" do
  def setup
    @namespace = "theplaylist"
    @store = Redis::Store.new :namespace => @namespace, :serializer => nil
    @client = @store.instance_variable_get(:@client)
    @rabbit = "bunny"
    @default_store = Redis::Store.new
    @other_namespace = 'other'
    @other_store = Redis::Store.new :namespace => @other_namespace
  end

  def teardown
    @store.flushdb
    @store.quit

    @default_store.flushdb
    @default_store.quit

    @other_store.flushdb
    @other_store.quit
  end

  it "only decorates instances that need to be namespaced" do
    store  = Redis::Store.new
    client = store.instance_variable_get(:@client)
    # `call_v` used since redis-rb 5.0
    client_call_method_name = client.respond_to?(:call_v) ? :call_v : :call
    client.expects(client_call_method_name).with([:get, "rabbit"])
    store.get("rabbit")
  end

  it "doesn't namespace a key which is already namespaced" do
    _(@store.send(:interpolate, "#{@namespace}:rabbit")).must_equal("#{@namespace}:rabbit")
  end

  it "should only delete namespaced keys" do
    @default_store.set 'abc', 'cba'
    @store.set 'def', 'fed'

    @store.flushdb
    _(@store.get('def')).must_be_nil
    _(@default_store.get('abc')).must_equal('cba')
  end

  it 'should allow to change namespace on the fly' do
    @default_store.set 'abc', 'cba'
    @other_store.set 'foo', 'bar'

    _(@default_store.keys).must_include('abc')
    _(@default_store.keys).must_include('other:foo')

    @default_store.with_namespace(@other_namespace) do
      _(@default_store.keys).must_equal ['foo']
      _(@default_store.get('foo')).must_equal('bar')
    end
  end

  it "should not try to delete missing namespaced keys" do
    empty_store = Redis::Store.new :namespace => 'empty'
    empty_store.flushdb
    _(empty_store.keys).must_be_empty
  end

  it "should work with dynamic namespace" do
    $ns = "ns1"
    dyn_store = Redis::Store.new :namespace => -> { $ns }
    dyn_store.set 'key', 'x'
    $ns = "ns2"
    dyn_store.set 'key', 'y'
    $ns = "ns3"
    dyn_store.set 'key', 'z'
    dyn_store.flushdb
    r3 = dyn_store.get 'key'
    $ns = "ns2"
    r2 = dyn_store.get 'key'
    $ns = "ns1"
    r1 = dyn_store.get 'key'
    _(r1).must_equal('x') && _(r2).must_equal('y') && _(r3).must_be_nil
  end

  it "namespaces setex and ttl" do
    @store.flushdb
    @other_store.flushdb

    @store.setex('foo', 30, 'bar')
    _(@store.ttl('foo')).must_be_close_to(30)
    _(@store.get('foo')).must_equal('bar')

    _(@other_store.ttl('foo')).must_equal(-2)
    _(@other_store.get('foo')).must_be_nil
  end

  describe 'method calls' do
    let(:store) { Redis::Store.new :namespace => @namespace, :serializer => nil }
    let(:client) { store.instance_variable_get(:@client) }
    let(:client_call_method_name) do
      # `call_v` used since redis-rb 5.0
      client.respond_to?(:call_v) ? :call_v : :call
    end

    it "should namespace get" do
      client.expects(client_call_method_name).with([:get, "#{@namespace}:rabbit"]).once
      store.get("rabbit")
    end

    it "should namespace set" do
      client.expects(client_call_method_name).with([:set, "#{@namespace}:rabbit", @rabbit])
      store.set "rabbit", @rabbit
    end

    it "should namespace setnx" do
      client.expects(client_call_method_name).with([:setnx, "#{@namespace}:rabbit", @rabbit])
      store.setnx "rabbit", @rabbit
    end

    it "should namespace del with single key" do
      client.expects(client_call_method_name).with([:del, "#{@namespace}:rabbit"])
      store.del "rabbit"
    end

    it "should namespace del with multiple keys" do
      client.expects(client_call_method_name).with([:del, "#{@namespace}:rabbit", "#{@namespace}:white_rabbit"])
      store.del "rabbit", "white_rabbit"
    end

    it "should namespace keys" do
      store.set "rabbit", @rabbit
      _(store.keys("rabb*")).must_equal [ "rabbit" ]
    end

    it "should namespace scan when a pattern is given" do
      store.set "rabbit", @rabbit
      cursor = "0"
      keys = []
      begin
        cursor, matched_keys = store.scan(cursor, match: "rabb*")
        keys = keys.concat(matched_keys) unless matched_keys.empty?
      end until cursor == "0"
      _(keys).must_equal [ "rabbit" ]
    end

    it "should namespace exists" do
      client.expects(client_call_method_name).with([:exists, "#{@namespace}:rabbit"])
      store.exists "rabbit"
    end

    it "should namespace incrby" do
      client.expects(client_call_method_name).with([:incrby, "#{@namespace}:counter", 1])
      store.incrby "counter", 1
    end

    it "should namespace decrby" do
      client.expects(client_call_method_name).with([:decrby, "#{@namespace}:counter", 1])
      store.decrby "counter", 1
    end

    it "should namespace mget" do
      client.expects(client_call_method_name).with([:mget, "#{@namespace}:rabbit", "#{@namespace}:white_rabbit"]).returns(%w[ foo bar ])
      store.mget "rabbit", "white_rabbit" do |result|
        _(result).must_equal(%w[ foo bar ])
      end
    end

    it "should namespace mapped_mget" do
      if client.respond_to?(:process, true)
        # Redis < 5.0 uses `#process`
        client.expects(:process).with([[:mget, "#{@namespace}:rabbit", "#{@namespace}:white_rabbit"]]).returns(%w[ foo bar ])
      else
        # Redis 5.x calls `#ensure_connected` (private)
        client.send(:ensure_connected).expects(:call).returns(%w[ foo bar ])
      end
      result = store.mapped_mget "rabbit", "white_rabbit"
      _(result.keys).must_equal %w[ rabbit white_rabbit ]
      _(result["rabbit"]).must_equal "foo"
      _(result["white_rabbit"]).must_equal "bar"
    end

    it "should namespace expire" do
      client.expects(client_call_method_name).with([:expire, "#{@namespace}:rabbit", 60]).once
      store.expire("rabbit", 60)
    end

    it "should namespace ttl" do
      client.expects(client_call_method_name).with([:ttl, "#{@namespace}:rabbit"]).once
      store.ttl("rabbit")
    end

    it "should namespace watch" do
      client.expects(client_call_method_name).with([:watch, "#{@namespace}:rabbit"]).once
      store.watch("rabbit")
    end

    it "wraps flushdb with appropriate KEYS * calls" do
      client.expects(client_call_method_name).with([:flushdb]).never
      client.expects(client_call_method_name).with([:keys, "#{@namespace}:*"]).once.returns(["rabbit"])
      client.expects(client_call_method_name).with([:del, "#{@namespace}:rabbit"]).once
      store.flushdb
    end

    it "skips flushdb wrapping if the namespace is nil" do
      client.expects(client_call_method_name).with([:flushdb])
      client.expects(client_call_method_name).with([:keys]).never
      store.with_namespace(nil) do
        store.flushdb
      end
    end

    it "should namespace hdel" do
      client.expects(client_call_method_name).with([:hdel, "#{@namespace}:rabbit", "key1", "key2"]).once
      store.hdel("rabbit", "key1", "key2")
    end

    it "should namespace hget" do
      client.expects(client_call_method_name).with([:hget, "#{@namespace}:rabbit", "key"]).once
      store.hget("rabbit", "key")
    end

    it "should namespace hgetall" do
      client.expects(client_call_method_name).with([:hgetall, "#{@namespace}:rabbit"]).once
      store.hgetall("rabbit")
    end

    it "should namespace hexists" do
      client.expects(client_call_method_name).with([:hexists, "#{@namespace}:rabbit", "key"]).once
      store.hexists("rabbit", "key")
    end

    it "should namespace hincrby" do
      client.expects(client_call_method_name).with([:hincrby, "#{@namespace}:rabbit", "key", 1]).once
      store.hincrby("rabbit", "key", 1)
    end

    it "should namespace hincrbyfloat" do
      client.expects(client_call_method_name).with([:hincrbyfloat, "#{@namespace}:rabbit", "key", 1.5]).once
      store.hincrbyfloat("rabbit", "key", 1.5)
    end

    it "should namespace hkeys" do
      client.expects(client_call_method_name).with([:hkeys, "#{@namespace}:rabbit"])
      store.hkeys("rabbit")
    end

    it "should namespace hlen" do
      client.expects(client_call_method_name).with([:hlen, "#{@namespace}:rabbit"])
      store.hlen("rabbit")
    end

    it "should namespace hmget" do
      client.expects(client_call_method_name).with([:hmget, "#{@namespace}:rabbit", "key1", "key2"])
      store.hmget("rabbit", "key1", "key2")
    end

    it "should namespace hmset" do
      client.expects(client_call_method_name).with([:hmset, "#{@namespace}:rabbit", "key", @rabbit])
      store.hmset("rabbit", "key", @rabbit)
    end

    it "should namespace hset" do
      client.expects(client_call_method_name).with([:hset, "#{@namespace}:rabbit", "key", @rabbit])
      store.hset("rabbit", "key", @rabbit)
    end

    it "should namespace hsetnx" do
      client.expects(client_call_method_name).with([:hsetnx, "#{@namespace}:rabbit", "key", @rabbit])
      store.hsetnx("rabbit", "key", @rabbit)
    end

    it "should namespace hvals" do
      client.expects(client_call_method_name).with([:hvals, "#{@namespace}:rabbit"])
      store.hvals("rabbit")
    end

    it "should namespace hscan" do
      client.expects(client_call_method_name).with([:hscan, "#{@namespace}:rabbit", 0])
      store.hscan("rabbit", 0)
    end

    it "should namespace hscan_each with block" do
      client.public_send(client_call_method_name, [:hset, "#{@namespace}:rabbit", "key1", @rabbit])
      client.expects(client_call_method_name).with([:hscan, "#{@namespace}:rabbit", 0]).returns(["0", ["key1"]])
      results = []
      store.hscan_each("rabbit") do |key|
        results << key
      end
      _(results).must_equal(["key1"])
    end

    it "should namespace hscan_each without block" do
      client.public_send(client_call_method_name, [:hset, "#{@namespace}:rabbit", "key1", @rabbit])
      client.expects(client_call_method_name).with([:hscan, "#{@namespace}:rabbit", 0]).returns(["0", ["key1"]])
      results = store.hscan_each("rabbit").to_a
      _(results).must_equal(["key1"])
    end

    it "should namespace zincrby" do
      client.expects(client_call_method_name).with([:zincrby, "#{@namespace}:rabbit", 1.0, "member"])
      store.zincrby("rabbit", 1.0, "member")
    end

    it "should namespace zscore" do
      client.expects(client_call_method_name).with([:zscore, "#{@namespace}:rabbit", "member"])
      store.zscore("rabbit", "member")
    end

    it "should namespace zadd" do
      client.expects(client_call_method_name).with([:zadd, "#{@namespace}:rabbit", 1.0, "member"])
      store.zadd("rabbit", 1.0, "member")
    end

    it "should namespace zrem" do
      client.expects(client_call_method_name).with([:zrem, "#{@namespace}:rabbit", "member"])
      store.zrem("rabbit", "member")
    end
  end
end
