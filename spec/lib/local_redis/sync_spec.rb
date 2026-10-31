require "spec_helper"
require "active_support/cache"
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
    expect { daemon.run_once }.to raise_error(RedisClient::ConnectionError, /not acknowledged/)
    expect(local.get(l1.lease_key)).to be_nil
  end
end
