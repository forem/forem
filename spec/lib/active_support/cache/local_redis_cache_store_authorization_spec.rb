require "rails_helper"
require_relative "../../../../lib/active_support/cache/local_redis_cache_store"
require_relative "../../../support/local_redis_servers"

RSpec.describe ActiveSupport::Cache::LocalRedisCacheStore do
  include_context "with real Redis"

  let(:servers) { LocalRedisServers.new }
  let(:remote_url) { servers.start("remote") }
  let(:local_url) { servers.start("local") }
  let(:store) { described_class.new(url: remote_url, local_url: local_url) }
  let(:local) { Redis.new(url: local_url) }
  let(:l1) { LocalRedis::Cache.new(url: local_url, source_url: remote_url) }
  let(:user) { create(:user) }

  before do
    allow(Rails).to receive(:cache).and_return(store)
    l1.heartbeat(LocalRedis::Cache.monotonic_time)
  end

  after do
    l1.close
    local.close
    servers.close
  end

  def expect_local_hit
    yield # The first fetch computes/writes; this read warms the disposable L1.
    # No remote cache access is possible during the repeated application call.
    allow(store.redis).to receive(:then).and_raise("unexpected hosted cache read")
    yield
  ensure
    allow(store.redis).to receive(:then).and_call_original
  end

  it "serves cached role names from L1 and evicts them when roles change" do
    user.add_role(:base_subscriber)
    user.reload
    expect(user.cached_role_names).to include("base_subscriber")
    expect_local_hit { expect(user.cached_role_names).to include("base_subscriber") }
    allow(store.redis).to receive(:then).and_call_original
    user.remove_role(:base_subscriber)
    user.reload
    expect(user.cached_role_names).not_to include("base_subscriber")
  end

  it "serves tag and subforem moderator scopes from L1" do
    allow(user).to receive_messages(moderator_for_tags_not_cached: ["ruby"],
                                    moderator_for_subforems_not_cached: ["example.com"])
    expect(user.moderator_for_tags).to eq(["ruby"])
    expect(user.moderator_for_subforems).to eq(["example.com"])
    expect_local_hit do
      expect(user.moderator_for_tags).to eq(["ruby"])
      expect(user.moderator_for_subforems).to eq(["example.com"])
    end
  end

  it "serves user block lists from L1 and evicts them on an unblock" do
    blocked = create(:user)
    block = create(:user_block, blocker: user, blocked: blocked)
    expect(UserBlock.cached_blocked_ids_for_blocker(user.id)).to eq([blocked.id])
    expect_local_hit { expect(UserBlock.cached_blocked_ids_for_blocker(user.id)).to eq([blocked.id]) }
    allow(store.redis).to receive(:then).and_call_original
    block.destroy!
    expect(UserBlock.cached_blocked_ids_for_blocker(user.id)).to eq([])
  end

  it "serves subscription checks from L1 including a cached false result" do
    params = { source_type: "Article", source_id: 123 }
    expect(UserSubscriptions::IsSubscribedCacheChecker.call(user, params)).to be(false)
    expect_local_hit { expect(UserSubscriptions::IsSubscribedCacheChecker.call(user, params)).to be(false) }
  end

  it "uses Rack::Attack's Redis adapter for raw authoritative counters and reset" do
    cache = Rack::Attack::Cache.new(store: store)
    expect(cache.store).to be_a(LocalRedis::RackAttackProxy)
    expect(cache.count("audit", 60)).to eq(1)
    expect(cache.count("audit", 60)).to eq(2)
    cache.write("probe", 3, 60)
    local.set("#{l1.data_prefix}rack::attack:probe", "99")
    store.with_local_cache do
      expect(cache.read("probe")).to eq("3")
      cache.write("probe", 4, 60)
      expect(cache.read("probe")).to eq("4")
    end
    cache.reset!
    expect(cache.read("probe")).to be_nil
  end

  it "serves trusted role checks from L1 (including cached false) and evicts them when trusted role changes" do
    expect(Authorizer.for(user: user).trusted?).to be(false)
    expect_local_hit { expect(Authorizer.for(user: user).trusted?).to be(false) }

    user.add_role(:trusted)
    expect(Authorizer.for(user: user.reload).trusted?).to be(true)
    expect_local_hit { expect(Authorizer.for(user: user).trusted?).to be(true) }

    user.remove_role(:trusted)
    expect(Authorizer.for(user: user.reload).trusted?).to be(false)
  end

  it "serves Rack::Attack admin API keys from L1 and evicts them on key create/destroy and admin role grant/revoke" do
    admin = create(:user, :admin)
    secret = create(:api_secret, user: admin)
    request = Rack::Attack::Request.new("HTTP_API_KEY" => secret.secret)

    expect(Rack::Attack.admin_api_key?(request)).to be(true)
    expect_local_hit { expect(Rack::Attack.admin_api_key?(request)).to be(true) }

    # Revoking the admin role evicts the cached key list
    admin.remove_role(:admin)
    expect(Rack::Attack.admin_api_key?(request)).to be(false)
    expect_local_hit { expect(Rack::Attack.admin_api_key?(request)).to be(false) }

    # Re-granting the admin role evicts the cached key list
    admin.add_role(:admin)
    expect(Rack::Attack.admin_api_key?(request)).to be(true)

    # Destroying the ApiSecret evicts the cached key list
    secret.destroy!
    expect(Rack::Attack.admin_api_key?(request)).to be(false)
  end

  it "serves Googlebot IP prefixes from L1 and evicts them when prefixes are updated" do
    key = GooglebotVerifier::CACHE_KEY
    store.write(key, ["192.0.2.0/27"], expires_in: 24.hours)

    expect(GooglebotVerifier.googlebot?("192.0.2.1")).to be(true)
    expect_local_hit do
      expect(GooglebotVerifier.googlebot?("192.0.2.1")).to be(true)
      expect(GooglebotVerifier.googlebot?("198.51.100.1")).to be(false)
    end

    store.write(key, [], expires_in: 5.minutes)
    expect(GooglebotVerifier.googlebot?("192.0.2.1")).to be(false)
  end

  it "serves active ThrottledCall markers from L1 without caching nil misses" do
    calls = 0
    ThrottledCall.perform(:l1_throttle_probe, throttle_for: 1.minute) { calls += 1 }
    expect(calls).to eq(1)

    expect_local_hit do
      ThrottledCall.perform(:l1_throttle_probe, throttle_for: 1.minute) { calls += 1 }
    end
    expect(calls).to eq(1)

    store.delete("throttled_call.l1_throttle_probe")
    ThrottledCall.perform(:l1_throttle_probe, throttle_for: 1.minute) { calls += 1 }
    expect(calls).to eq(2)
  end
end
