require "spec_helper"
require_relative "../../../lib/active_support/cache/local_redis_cache_store"
require_relative "../../../lib/betterstack/stats_client"
require_relative "../../../lib/local_redis/metrics"
require_relative "../../support/local_redis_servers"

RSpec.describe LocalRedis::Metrics do
  include_context "with real Redis"

  let(:now) { [0.0] }
  let(:stats_client) { instance_double(Betterstack::StatsClient, count: nil) }
  let(:metrics) { described_class.new(stats_client: stats_client, clock: -> { now.first }) }

  def read_event(hits:, misses:)
    metrics.record_read(hits, misses)
  end

  def bypass_event
    metrics.record_bypass
  end

  it "reports aggregated totals at most once per interval, skipping zero counts" do
    read_event(hits: 3, misses: 1)
    bypass_event
    now[0] = 59.9
    read_event(hits: 1, misses: 0)
    expect(stats_client).not_to have_received(:count)

    now[0] = 60
    read_event(hits: 2, misses: 0)
    expect(stats_client).to have_received(:count).with("local_redis_cache.hits", 6).once
    expect(stats_client).to have_received(:count).with("local_redis_cache.misses", 1).once
    expect(stats_client).to have_received(:count).with("local_redis_cache.bypasses", 1).once

    now[0] = 121
    read_event(hits: 4, misses: 0)
    expect(stats_client).to have_received(:count).with("local_redis_cache.hits", 4).once
    expect(stats_client).to have_received(:count).exactly(4).times
  end

  it "never raises into a cache read when the stats backend fails" do
    allow(stats_client).to receive(:count).and_raise("stats outage")
    now[0] = 60
    expect { read_event(hits: 1, misses: 0) }.not_to raise_error
  end

  it "counts real store reads once installed on the store" do
    servers = LocalRedisServers.new
    remote_url = servers.start("remote")
    local_url = servers.start("local")
    l1 = LocalRedis::Cache.new(url: local_url, source_url: remote_url)
    store = ActiveSupport::Cache::LocalRedisCacheStore.new(url: remote_url, local_url: local_url)
    store.metrics = metrics
    store.write("key", "value")

    store.read("key") # No health lease yet: bypass.
    l1.heartbeat(LocalRedis::Cache.monotonic_time)
    store.read("key") # Miss, then fill.
    now[0] = 60
    store.read("key") # Hit, then report.

    expect(stats_client).to have_received(:count).with("local_redis_cache.bypasses", 1)
    expect(stats_client).to have_received(:count).with("local_redis_cache.misses", 1)
    expect(stats_client).to have_received(:count).with("local_redis_cache.hits", 1)
  ensure
    l1&.close
    servers&.close
  end

  describe ".install" do
    it "does nothing for the default cache store" do
      allow(ActiveSupport::ForkTracker).to receive(:after_fork)
      expect(described_class.install(ActiveSupport::Cache::MemoryStore.new, stats_client: stats_client)).to be_nil
      expect(ActiveSupport::ForkTracker).not_to have_received(:after_fork)
    end

    it "attaches to the local cache store and drops counts inherited across a fork" do
      # Construction is lazy: neither Redis is contacted.
      store = ActiveSupport::Cache::LocalRedisCacheStore.new(url: "redis://localhost:1/0",
                                                             local_url: "unix:///tmp/forem-metrics-spec.sock")
      recorder = Class.new do
        attr_reader :calls

        def initialize
          @calls = []
        end

        def count(*args)
          @calls << args
        end
      end.new

      installed = described_class.install(store, stats_client: recorder, clock: -> { now.first })
      expect(store.metrics).to be(installed)

      installed.record_read(5, 5)
      # A real fork, as Puma does after preloading; exit! skips RSpec's at_exit hooks.
      pid = Process.fork do
        now[0] = 60
        installed.record_read(1, 0)
        exit!(recorder.calls == [["local_redis_cache.hits", 1]])
      end
      Process.wait(pid)
      expect(Process.last_status).to be_success
    end
  end
end
