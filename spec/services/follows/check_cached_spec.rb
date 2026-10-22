require "rails_helper"

RSpec.describe Follows::CheckCached, type: :service do
  let(:user) { create(:user) }

  it "checks if following a thing and returns true if they are" do
    user2 = create(:user)
    user.follow(user2)
    expect(described_class.call(user, "User", user2.id)).to be(true)
  end

  it "checks if following a thing and returns false if they are not" do
    user2 = create(:user)
    expect(described_class.call(user, "User", user2.id)).to be(false)
  end

  it "checks tag follows" do
    tag = create(:tag)
    user.follow(tag)
    expect(described_class.call(user, "Tag", tag.id)).to be(true)
  end

  it "raises when the followable does not exist" do
    expect { described_class.call(user, "User", 0) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "loads only the followable's id" do
    user2 = create(:user)
    queries = []
    callback = ->(*, payload) { queries << payload[:sql] }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      described_class.call(user, "User", user2.id)
    end
    expect(queries).to include(a_string_including('SELECT "users"."id" FROM "users"'))
    expect(queries).not_to include(a_string_including('SELECT "users".* FROM "users"'))
  end

  describe ".read_multi" do
    let(:cache) { ActiveSupport::Cache::MemoryStore.new }
    let(:followed) { create(:user) }
    let(:not_followed) { create(:user) }
    let(:checks) { [[user, "User", followed.id], [user, "User", not_followed.id], [nil, "User", followed.id]] }

    before do
      allow(Rails).to receive(:cache).and_return(cache)
      user.follow(followed)
    end

    it "returns only already-cached results, in a single cache read" do
      described_class.call(user, "User", followed.id)
      allow(cache).to receive(:read_multi).and_call_original

      prefetched = described_class.read_multi(checks)

      expect(cache).to have_received(:read_multi).once
      expect(prefetched.values).to eq([true])
    end

    it "returns the same results as .call while skipping per-check cache reads" do
      described_class.call(user, "User", not_followed.id)
      prefetched = described_class.read_multi(checks)
      allow(cache).to receive(:read).and_call_original
      allow(cache).to receive(:fetch).and_call_original

      results = checks.map { |args| described_class.call(*args, prefetched) }

      expect(results).to eq([true, false, false])
      expect(cache).not_to have_received(:read)
      expect(cache).not_to have_received(:fetch)
      expect(described_class.read_multi(checks).values).to contain_exactly(true, false)
    end

    it "returns an empty hash without reading the cache when there is nothing to check" do
      allow(cache).to receive(:read_multi)

      expect(described_class.read_multi([[nil, "User", followed.id]])).to eq({})
      expect(cache).not_to have_received(:read_multi)
    end
  end
end
