require "spec_helper"
require "active_support/cache"
require "json"
require "zlib"
require_relative "../../../../lib/active_support/cache/local_redis_cache_store"
require_relative "../../../support/local_redis_servers"

RSpec.describe ActiveSupport::Cache::LocalRedisCacheStore do
  include_context "with real Redis"

  let(:servers) { LocalRedisServers.new }
  let(:remote_url) { servers.start("remote") }
  let(:local_url) { servers.start("local") }
  let(:remote) { Redis.new(url: remote_url) }
  let(:local) { Redis.new(url: local_url) }
  let(:l1) { LocalRedis::Cache.new(url: local_url, source_url: remote_url) }
  let(:store) { described_class.new(url: remote_url, local_url: local_url, serializer: :marshal_7_1) }
  let(:vanilla) { ActiveSupport::Cache::RedisCacheStore.new(url: remote_url, serializer: :marshal_7_1) }

  before { l1.heartbeat(LocalRedis::Cache.monotonic_time) }

  after do
    l1.close
    remote.close
    local.close
    servers.close
  end

  def local_value(key)
    local.get("#{l1.data_prefix}#{key}")
  end

  it "fills lazily, then serves a serialized local hit without accessing hosted Redis" do
    vanilla.write("article", { "title" => "hello" })
    expect(store.read("article")).to eq("title" => "hello")
    expect(local_value("article")).to eq(remote.get("article"))
    allow(store.redis).to receive(:then).and_raise("unexpected remote access")
    expect(store.read("article")).to eq("title" => "hello")
  end

  it "batches only misses while preserving multi-read order and absent keys" do
    vanilla.write_multi("a" => 1, "b" => false, "c" => nil)
    store.read("a")
    remote.del("a") # Deliberately keep this local hit; no daemon in this example.
    expect(store.read_multi("a", "b", "c", "absent")).to eq("a" => 1, "b" => false, "c" => nil)
    expect(store.fetch_multi("a", "d") { 4 }).to eq("a" => 1, "d" => 4)
    expect(vanilla.read("d")).to eq(4)
  end

  it "memoizes present values and misses within a request without either Redis round trip" do
    vanilla.write("present", false)
    allow(LocalRedis::Cache).to receive(:new).with(url: local_url, source_url: remote_url).and_return(l1)
    allow(l1).to receive(:read).and_call_original
    allow(store.redis).to receive(:then).and_call_original
    store.with_local_cache do
      5.times do
        expect(store.read("present")).to be(false)
        expect(store.read("absent")).to be_nil
      end
    end
    expect(l1).to have_received(:read).with(["present"]).once
    expect(l1).to have_received(:read).with(["absent"]).once
    expect(store.redis).to have_received(:then).twice
  end

  it "shares serialized request entries and misses across single and batched reads" do
    vanilla.write_multi("a" => false, "b" => nil)
    allow(LocalRedis::Cache).to receive(:new).with(url: local_url, source_url: remote_url).and_return(l1)
    allow(l1).to receive(:read).and_call_original
    allow(store.redis).to receive(:then).and_call_original
    store.with_local_cache do
      expect(store.read("a")).to be(false)
      5.times do
        expect(store.read_multi("a", "b", "absent")).to eq("a" => false, "b" => nil)
        expect(store.read("b")).to be_nil
        expect(store.read("absent")).to be_nil
      end
    end
    expect(l1).to have_received(:read).with(["a"]).once
    expect(l1).to have_received(:read).with(%w[b absent]).once
    expect(store.redis).to have_received(:then).twice
  end

  it "keeps request memory coherent after single and bulk writes and deletes" do
    store.with_local_cache do
      expect(store.read_multi("a", "b")).to eq({})
      store.write("a", "single")
      expect(store.read("a")).to eq("single")
      store.write_multi("a" => "bulk", "b" => false)
      expect(store.read_multi("a", "b")).to eq("a" => "bulk", "b" => false)
      store.delete_multi(%w[a b])
      expect(store.read("a")).to be_nil
      expect(store.read_multi("a", "b")).to eq({})
      expect(store.fetch_multi("a", "b") { "regenerated" }).to eq("a" => "regenerated", "b" => "regenerated")
      store.delete("a")
      expect(store.read("a")).to be_nil
    end
  end

  it "drops request memoization between requests while retaining L1 hits" do
    vanilla.write("a", "value")
    store.with_local_cache do
      store.read("a")
      expect(store.read("absent")).to be_nil
    end
    l1.invalidate(["a"])
    vanilla.write("a", "new")
    vanilla.write("absent", "now present")
    store.with_local_cache do
      expect(store.read("a")).to eq("new")
      expect(store.read("absent")).to eq("now present")
    end
  end

  it "preserves versioned keys, compression, nil and fetch semantics" do
    key = Struct.new(:cache_key, :cache_version).new("article", "1")
    vanilla.write(key, "large" * 1000)
    expect(store.read(key)).to eq("large" * 1000)
    key.cache_version = "2"
    expect(store.read(key)).to be_nil
    expect(store.fetch(key) { "new" }).to eq("new")
    expect(vanilla.read(key)).to eq("new")
    expect(store.fetch("nil", skip_nil: true) { nil }).to be_nil
    expect(vanilla.exist?("nil")).to be(false)
  end

  it "never extends the hosted TTL and bounds entries with no hosted expiry" do
    vanilla.write("short", "value", expires_in: 0.2)
    store.read("short")
    expect(local.pttl("#{l1.data_prefix}short")).to be <= remote.pttl("short") + 5
    vanilla.write("forever", "value")
    store.read("forever")
    expect(local.pttl("#{l1.data_prefix}forever")).to be_between(1, 30_000)
    sleep 0.22
    expect(store.read("short")).to be_nil
  end

  it "applies a configured cap to single and batched fills without extending source TTLs" do
    stub_const("ENV", ENV.to_h.merge("LOCAL_REDIS_MAX_TTL" => "120"))
    vanilla.write_multi({ "forever" => "value", "long" => "value" }, expires_in: nil)
    vanilla.write("short", "value", expires_in: 60)
    store.read("forever")
    expect(store.read_multi("long", "short")).to eq("long" => "value", "short" => "value")
    expect(local.pttl("#{l1.data_prefix}forever")).to be_between(110_000, 120_000)
    expect(local.pttl("#{l1.data_prefix}long")).to be_between(110_000, 120_000)
    expect(local.pttl("#{l1.data_prefix}short")).to be_between(50_000, 60_000)
  end

  it "still revokes long-lived entries on lease loss when the cap is ten minutes" do
    stub_const("ENV", ENV.to_h.merge("LOCAL_REDIS_MAX_TTL" => "600"))
    vanilla.write("a", "old")
    store.read("a")
    expect(local.pttl("#{l1.data_prefix}a")).to be_between(590_000, 600_000)
    l1.disable
    vanilla.write("a", "new")
    expect(store.read("a")).to eq("new")
    l1.heartbeat(LocalRedis::Cache.monotonic_time)
    expect(local_value("a")).to be_nil
  end

  it "rejects a slow fill if an invalidation was processed during the hosted read" do
    vanilla.write("article", "old")
    allow(store.redis).to receive(:then).and_wrap_original do |original, &block|
      result = original.call(&block)
      l1.invalidate(["article"])
      result
    end
    expect(store.read("article")).to eq("old")
    expect(local_value("article")).to be_nil
  end

  def guard_bucket(key)
    Zlib.crc32(key) % LocalRedis::Cache::GUARD_BUCKETS
  end

  it "keeps a fill when only unrelated keys were invalidated during the hosted read" do
    vanilla.write("article", "value")
    unrelated = (1..).lazy.map { |i| "unrelated-#{i}" }.detect { |key| guard_bucket(key) != guard_bucket("article") }
    allow(store.redis).to receive(:then).and_wrap_original do |original, &block|
      result = original.call(&block)
      l1.invalidate([unrelated, "other-#{unrelated}"])
      result
    end
    expect(store.read("article")).to eq("value")
    expect(local_value("article")).to eq(remote.get("article"))
  end

  it "conservatively drops a fill when a colliding key shares its guard bucket" do
    vanilla.write("article", "value")
    colliding = (1..).lazy.map { |i| "colliding-#{i}" }.detect { |key| guard_bucket(key) == guard_bucket("article") }
    allow(store.redis).to receive(:then).and_wrap_original do |original, &block|
      result = original.call(&block)
      l1.invalidate([colliding])
      result
    end
    expect(store.read("article")).to eq("value")
    expect(local_value("article")).to be_nil
  end

  it "bypasses L1 if the guard hash is evicted, then flushes before re-enabling" do
    vanilla.write("a", "old")
    store.read("a")
    local.del(l1.guards_key)
    vanilla.write("a", "new")
    expect(store.read("a")).to eq("new")
    l1.heartbeat(LocalRedis::Cache.monotonic_time)
    expect(local_value("a")).to be_nil
    expect(store.read("a")).to eq("new")
    expect(local_value("a")).to eq(remote.get("a"))
  end

  it "rejects an in-flight fill when eviction removes its guard epoch" do
    vanilla.write("a", "old")
    allow(store.redis).to receive(:then).and_wrap_original do |original, &block|
      result = original.call(&block)
      local.del(l1.guards_key)
      l1.invalidate(["a"]) # Recreates a bucket, but cannot recreate the epoch.
      result
    end
    expect(store.read("a")).to eq("old")
    expect(local_value("a")).to be_nil
  end

  it "rejects a delayed fill after a whole-cache flush and heartbeat recovery" do
    vanilla.write("a", "old")
    allow(store.redis).to receive(:then).and_wrap_original do |original, &block|
      result = original.call(&block)
      l1.invalidate(nil)
      l1.heartbeat(LocalRedis::Cache.monotonic_time)
      result
    end
    expect(store.read("a")).to eq("old")
    expect(local_value("a")).to be_nil
  end

  it "synchronously evicts successful, failed-NX, and bulk writes on this host" do
    vanilla.write("a", "old")
    store.read("a")
    expect(store.write("a", "ignored", unless_exist: true)).to be(false)
    expect(local_value("a")).to be_nil
    store.read("a")
    store.write_multi("a" => "new", "b" => "bulk")
    expect(local_value("a")).to be_nil
    expect(store.read_multi("a", "b")).to eq("a" => "new", "b" => "bulk")
    expect(store.delete_multi(%w[a b])).to eq(2)
    expect(store.read_multi("a", "b")).to eq({})
  end

  it "leaves raw reads, raw multi-reads, NX and counters authoritative" do
    store.write("counter", 0, raw: true)
    local.set("#{l1.data_prefix}counter", "99")
    expect(store.increment("counter", 2, expires_in: 60)).to eq(2)
    expect(store.decrement("counter", 1)).to eq(1)
    local.set("#{l1.data_prefix}counter", "99")
    expect(store.read("counter", raw: true)).to eq("1")
    expect(store.read_multi("counter", raw: true)).to eq("counter" => "1")
    expect(store.write("counter", "other", raw: true, unless_exist: true)).to be(false)
    expect(remote.ttl("counter")).to be_between(1, 60)
  end

  it "falls back on local failure, absent lease, and local eviction" do
    vanilla.write("a", "authoritative")
    store.read("a")
    local.del("#{l1.data_prefix}a")
    expect(store.read("a")).to eq("authoritative")
    l1.disable
    vanilla.write("a", "new")
    expect(store.read_multi("a")).to eq("a" => "new")
    broken = described_class.new(url: remote_url, local_url: "unix://#{servers.directory}/missing.sock")
    expect(broken.read("a")).to eq("new")
    expect(broken.write("a", "still writes")).to be(true)
    expect(vanilla.read("a")).to eq("still writes")
  end

  it "bypasses stale entries when the lease expires and flushes them before re-enabling L1" do
    vanilla.write("a", "old")
    store.read("a")
    local.pexpire(l1.lease_key, 1)
    sleep 0.01
    vanilla.write("a", "new")
    expect(store.read("a")).to eq("new")
    l1.heartbeat(LocalRedis::Cache.monotonic_time)
    expect(local_value("a")).to be_nil
    expect(store.read("a")).to eq("new")
  end

  it "does not refresh a lease from a delayed heartbeat" do
    l1.disable
    l1.heartbeat(LocalRedis::Cache.monotonic_time - 4)
    expect(local.get(l1.lease_key)).to be_nil
  end

  it "clears local state for pattern deletion and clear while preserving namespace isolation remotely" do
    store = described_class.new(url: remote_url, local_url: local_url, namespace: "one")
    vanilla.write("unrelated", "keep")
    store.write("a", "value")
    store.read("a")
    store.delete_matched("a*")
    expect(store.read("a")).to be_nil
    store.write("b", "value")
    store.clear
    expect(store.read("b")).to be_nil
    expect(vanilla.read("unrelated")).to eq("keep")
  end

  it "preserves hosted failure semantics even when local entries are present" do
    vanilla.write("a", "cached")
    store.read("a")
    allow(store.redis).to receive(:then).and_raise(Redis::CannotConnectError)
    expect(store.read("a")).to eq("cached")
    expect(store.read("missing")).to be_nil
    expect(store.read_multi("a", "missing")).to eq("a" => "cached")
    l1.disable
    expect(store.read_multi("a")).to eq({})
  end

  it "retains readable remote values when the provider rejects read-through scripts" do
    vanilla.write("a", "value")
    warning_logger = instance_double(Logger, debug?: false)
    allow(warning_logger).to receive(:warn).and_raise(IOError, "logger unavailable")
    allow(store).to receive(:logger).and_return(warning_logger)
    store.redis.then do |client|
      allow(client).to receive(:pipelined).and_raise(Redis::CommandError, "NOPERM EVAL")
    end
    expect(store.read("a")).to eq("value")
    expect(store.read_multi("a")).to eq("a" => "value")
    expect(local_value("a")).to be_nil
    expect(warning_logger).to have_received(:warn).once
  end

  it "retains fetch race-condition TTL behavior and does not extend local TTL with it" do
    store.write("race", "old", expires_in: 0.05, race_condition_ttl: 1)
    expect(store.read("race")).to eq("old")
    sleep 0.07
    expect(store.fetch("race", expires_in: 1, race_condition_ttl: 1) { "new" }).to eq("new")
    expect(vanilla.read("race")).to eq("new")
    expect(remote.pttl("race")).to be > 1000
  end

  it "reconnects inherited local and remote pools after a Puma-style worker fork" do
    vanilla.write("a", "value")
    store.read("a")
    reader, writer = IO.pipe
    pid = fork do
      reader.close
      writer.write(store.read("a"))
      writer.close
      exit! 0
    end
    writer.close
    expect(reader.read).to eq("value")
    expect(Process.waitpid2(pid).last.exitstatus).to eq(0)
  ensure
    reader&.close
    writer&.close
  end

  it "keeps security and coordination reads authoritative with local_cache: false" do
    vanilla.write("permission", "old")
    store.read("permission")
    vanilla.write("permission", "new")
    expect(store.read("permission", local_cache: false)).to eq("new")
    expect(store.read_multi("permission", local_cache: false)).to eq("permission" => "new")
    expect(store.fetch("permission", local_cache: false) { "unexpected" }).to eq("new")
    expect(store.fetch_multi("permission", local_cache: false) { "unexpected" }).to eq("permission" => "new")
    vanilla.delete("permission")
    expect(store.exist?("permission", local_cache: false)).to be(false)
    expect(store.read("permission")).to eq("old")
  end

  it "bypasses Rails request memory as well as L1 for authoritative and raw reads" do
    store.with_local_cache do
      store.write("security", "old", local_cache: false)
      vanilla.write("security", "new")
      expect(store.read("security", local_cache: false)).to eq("new")
      expect(store.read_multi("security", local_cache: false)).to eq("security" => "new")
      expect(store.fetch_multi("security", local_cache: false) { "wrong" }).to eq("security" => "new")
      vanilla.delete("security")
      expect(store.exist?("security", local_cache: false)).to be(false)
      store.write("counter", 1, raw: true)
      remote.incr("counter")
      expect(store.read("counter", raw: true)).to eq("2")
      expect(store.fetch_multi("counter", raw: true) { "wrong" }).to eq("counter" => "2")
    end
  end

  it "never mixes entries from different authoritative endpoints on a reused sidecar" do
    vanilla.write("a", "first origin")
    store.read("a")
    other_url = servers.start("other")
    other = described_class.new(url: other_url, local_url: local_url)
    other.write("a", "second origin")
    other_l1 = LocalRedis::Cache.new(url: local_url, source_url: other_url)
    other_l1.heartbeat(LocalRedis::Cache.monotonic_time)
    expect(other.read("a")).to eq("second origin")
    expect(store.read("a")).to eq("first origin")
  ensure
    other_l1&.close
  end

  it "rejects unsupported routing and ambiguous custom clients before accessing L1" do
    expect { described_class.new(url: [remote_url], local_url: local_url) }.to raise_error(ArgumentError, /one URL/)
    expect { described_class.new(url: remote_url, redis: remote, local_url: local_url) }
      .to raise_error(ArgumentError, /one URL/)
    expect { described_class.new(url: remote_url, sentinels: [], local_url: local_url) }
      .to raise_error(ArgumentError, /one URL/)
    expect { described_class.new(url: remote_url, db: 1, local_url: local_url) }
      .to raise_error(ArgumentError, /one URL/)
    expect { described_class.new(url: local_url.sub("/local.sock", "/sub/../local.sock"), local_url: local_url) }
      .to raise_error(ArgumentError, /separate/)
  end

  it "preserves duplicate and long keys, dynamic namespaces, and custom serialization" do
    namespaced = described_class.new(url: remote_url, local_url: local_url, namespace: -> { "tenant" },
                                     serializer: JSON)
    key = "long" * 400
    namespaced.write(key, { "a" => false })
    expect(namespaced.read_multi(key, key)).to eq(key => { "a" => false })
    expect(namespaced.fetch_multi(key, key) { "wrong" }).to eq(key => { "a" => false })
  end

  it "rejects aliases of the authoritative socket, including before the socket exists" do
    socket = LocalRedis::Cache.socket_path(local_url)
    alias_path = File.join(servers.directory, "alias.sock")
    File.symlink(socket, alias_path)
    expect { described_class.new(url: "unix://#{alias_path}", local_url: local_url) }
      .to raise_error(ArgumentError, /separate/)

    hard_link = File.join(servers.directory, "hard-link.sock")
    File.link(socket, hard_link)
    expect { described_class.new(url: "unix://#{hard_link}", local_url: local_url) }
      .to raise_error(ArgumentError, /separate/)

    directory_alias = File.join(servers.directory, "alias-directory")
    File.symlink(servers.directory, directory_alias)
    expect do
      described_class.new(url: "unix://#{directory_alias}/future.sock",
                          local_url: "unix://#{servers.directory}/future.sock")
    end.to raise_error(ArgumentError, /separate/)
  end

  read_operations = %i[single mixed_multi]
  [Redis::TimeoutError, Redis::CannotConnectError, ConnectionPool::Error].each do |failure_class|
    read_operations.each do |operation|
      it "attempts hosted access and reports #{failure_class} only once for #{operation} reads" do
        reports = []
        tested = described_class.new(url: remote_url, local_url: local_url,
                                     error_handler: ->(**payload) { reports << payload })
        vanilla.write("a", "cached")
        tested.read("a")
        allow(tested.redis).to receive(:then).and_raise(failure_class)

        result = operation == :single ? tested.read("missing") : tested.read_multi("a", "missing")

        expect(result).to eq(operation == :single ? nil : { "a" => "cached" })
        expect(tested.redis).to have_received(:then).once
        expect(reports.size).to eq(1)
        expect(reports.first.fetch(:exception)).to be_a(failure_class)
      end
    end
  end

  read_operations.each do |operation|
    it "does not retry an actually exhausted hosted connection pool for #{operation} reads" do
      reports = []
      tested = described_class.new(url: remote_url, local_url: local_url, pool: { size: 1, timeout: 0.01 },
                                   error_handler: ->(**payload) { reports << payload })
      vanilla.write("a", "cached")
      tested.read("a")
      checked_out = Queue.new
      release = Queue.new
      holder = Thread.new do
        tested.redis.with do
          checked_out << true
          release.pop
        end
      end
      checked_out.pop
      allow(tested.redis).to receive(:then).and_call_original

      result = operation == :single ? tested.read("missing") : tested.read_multi("a", "missing")

      expect(result).to eq(operation == :single ? nil : { "a" => "cached" })
      expect(tested.redis).to have_received(:then).once
      expect(reports.size).to eq(1)
      expect(reports.first.fetch(:exception)).to be_a(ConnectionPool::TimeoutError)
    ensure
      release << true if release
      holder&.join
    end
  end

  it "falls back to ordinary reads when an actual provider disables EVAL" do
    unsupported_url = servers.start("eval-disabled", "--rename-command", "EVAL", "")
    unsupported_l1 = LocalRedis::Cache.new(url: local_url, source_url: unsupported_url)
    unsupported_l1.heartbeat(LocalRedis::Cache.monotonic_time)
    reports = []
    tested = described_class.new(url: unsupported_url, local_url: local_url,
                                 error_handler: ->(**payload) { reports << payload })
    warning_logger = instance_double(Logger, warn: nil, debug?: false)
    allow(tested).to receive(:logger).and_return(warning_logger)
    tested.write("a", "value")
    3.times do
      expect(tested.read("a")).to eq("value")
      expect(tested.read_multi("a", "missing")).to eq("a" => "value")
    end
    expect(warning_logger).to have_received(:warn).with(%r{rejected.*read-through.*GET/MGET}).once
    expect(reports).to be_empty
  ensure
    unsupported_l1&.close
  end
end
