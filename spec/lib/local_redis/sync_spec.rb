require "spec_helper"
require "active_support/cache"
require "zlib"
require_relative "../../../lib/active_support/cache/local_redis_cache_store"
require_relative "../../../lib/local_redis/sync"
require_relative "../../support/local_redis_servers"

RSpec.describe LocalRedis::Sync do
  include_context "with real Redis"

  let(:servers) { LocalRedisServers.new }
  let(:remote_url) { servers.start("remote") }
  let(:local_url) { servers.start("local") }
  let(:remote) { Redis.new(url: remote_url) }
  let(:local) { Redis.new(url: local_url) }
  let(:store) { ActiveSupport::Cache::LocalRedisCacheStore.new(url: remote_url, local_url: local_url) }
  let(:old_store) { ActiveSupport::Cache::RedisCacheStore.new(url: remote_url) }
  let(:l1) { LocalRedis::Cache.new(url: local_url, source_url: remote_url) }
  let(:daemon) { described_class.new(local_url: local_url, remote_url: remote_url, logger: Logger.new(File::NULL)) }
  let(:thread) { Thread.new { daemon.run } }

  before do
    thread.report_on_exception = false
    wait_until { local.get(l1.lease_key) }
  end

  after do
    thread.kill
    thread.join
    remote.close
    local.close
    servers.close
  end

  def wait_until
    deadline = LocalRedis::Cache.monotonic_time + 5
    until yield
      raise "Timed out waiting for invalidation" if LocalRedis::Cache.monotonic_time >= deadline

      sleep 0.01
    end
  end

  def local_value(key)
    local.get("#{l1.data_prefix}#{key}")
  end

  it "keeps filling and serving a stable key while other keys are written continuously" do
    bucket = ->(key) { Zlib.crc32(key) % LocalRedis::Cache::GUARD_BUCKETS }
    old_store.write("stable", "value")
    noise = (1..).lazy.map { |i| "noise-#{i}" }.reject { |key| bucket.call(key) == bucket.call("stable") }.first(500)
    writes = 0
    writer = Thread.new do
      writer_client = Redis.new(url: remote_url)
      loop do
        writer_client.incr(noise[writes % noise.size])
        writes += 1
      end
    ensure
      writer_client&.close
    end
    wait_until { local.hlen(l1.guards_key) > 100 } # Invalidations are flowing.
    writes_before_reads = writes

    remote_reads = 0
    allow(store.redis).to receive(:then).and_wrap_original do |original, &block|
      remote_reads += 1
      sleep 0.002 # A realistic hosted round trip, spanning many unrelated writes.
      original.call(&block)
    end
    100.times { expect(store.read("stable")).to eq("value") }

    expect(writes - writes_before_reads).to be > 10
    expect(remote_reads).to be <= 2
  ensure
    writer&.kill
    writer&.join
  end

  it "invalidates writes and deletes from an unmodified Rails store on another host" do
    old_store.write("article", "old")
    wait_until do
      store.read("article")
      local_value("article")
    end
    old_store.write("article", "new")
    wait_until { local_value("article").nil? }
    expect(store.read("article")).to eq("new")
    old_store.delete("article")
    wait_until { local_value("article").nil? }
    expect(store.read("article")).to be_nil
  end

  it "invalidates raw Redis changes, expiration, and a hosted FLUSHDB" do
    old_store.write("article", "old")
    wait_until do
      store.read("article")
      local_value("article")
    end
    remote.pexpire("article", 30)
    wait_until { local_value("article").nil? }
    sleep 0.04
    expect(store.read("article")).to be_nil
    old_store.write("other", "value")
    wait_until do
      store.read("other")
      local_value("other")
    end
    remote.flushdb
    wait_until { local_value("other").nil? }
    expect(store.read("other")).to be_nil
  end

  it "drops stale data across a lost tracking connection and resubscribes before warming" do
    old_store.write("article", "old")
    wait_until do
      store.read("article")
      local_value("article")
    end
    tracker = remote.client(:list).detect { |client| client.fetch("flags").include?("t") }
    tracker_id = tracker.fetch("id")
    remote.client(:kill, "ID", tracker_id)
    wait_until { local.get(l1.lease_key).nil? }
    old_store.write("article", "during gap")
    expect(store.read("article")).to eq("during gap")
    wait_until { local.get(l1.lease_key) }
    expect(local_value("article")).to be_nil
    expect(store.read("article")).to eq("during gap")
  end

  it "keeps L1 disabled if the provider rejects tracking" do
    thread.kill
    thread.join
    unsupported_url = servers.start("unsupported", "--rename-command", "CLIENT", "")
    daemon = described_class.new(local_url: local_url, remote_url: unsupported_url)
    unsupported_l1 = LocalRedis::Cache.new(url: local_url, source_url: unsupported_url)
    # Start eligible so this assertion detects failure to revoke an existing lease.
    unsupported_l1.heartbeat(LocalRedis::Cache.monotonic_time)
    expect(local.get(unsupported_l1.lease_key)).not_to be_nil
    expect { daemon.run_once }.to raise_error(RedisClient::ConnectionError, /not acknowledged/)
    expect(local.get(unsupported_l1.lease_key)).to be_nil
  ensure
    unsupported_l1&.close
  end
end
