# spec/lib/dependency_upgrades_sanity_spec.rb
require "rails_helper"
require "request_store"
require "timecop"

RSpec.describe "Dependency Upgrades Sanity Check" do
  describe "RequestStore upgrade to 1.7.0" do
    before { RequestStore.clear! }
    after { RequestStore.clear! }

    it "properly stores and retrieves data" do
      RequestStore.store[:test_key] = "test_value"
      expect(RequestStore.store[:test_key]).to eq("test_value")
    end

    it "clears the store on clear!" do
      RequestStore.store[:test_key] = "test_value"
      RequestStore.clear!
      expect(RequestStore.store[:test_key]).to be_nil
    end

    it "supports fetching with block" do
      result = RequestStore.fetch(:fetch_key) { "block_value" }
      expect(result).to eq("block_value")
      expect(RequestStore.store[:fetch_key]).to eq("block_value")
    end
  end

  describe "Timecop upgrade to 0.9.11" do
    after { Timecop.return }

    it "properly freezes and travels time" do
      target_time = Time.zone.parse("2026-01-01 12:00:00")
      Timecop.freeze(target_time)
      expect(Time.zone.now).to eq(target_time)

      Timecop.travel(3600) # 1 hour later
      expect(Time.zone.now).to be_within(1.second).of(target_time + 1.hour)
    end

    it "returns to actual time on return" do
      initial_time = Time.zone.now
      Timecop.freeze(1.day.ago)
      Timecop.return
      expect(Time.zone.now).to be_within(5.seconds).of(initial_time)
    end
  end
end
