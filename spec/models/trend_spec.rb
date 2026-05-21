require "rails_helper"

RSpec.describe Trend do
  let(:trend) { build(:trend) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(trend).to be_valid
    end

    it "is invalid without a name" do
      trend.name = nil
      expect(trend).not_to be_valid
    end

    it "is invalid without centroid_embedding" do
      trend.centroid_embedding = nil
      expect(trend).not_to be_valid
    end
    it "is invalid without first_observed_at" do
      trend.first_observed_at = nil
      expect(trend).not_to be_valid
    end

    it "is invalid without last_observed_at" do
      trend.last_observed_at = nil
      expect(trend).not_to be_valid
    end
  end

  describe "callbacks" do
    it "generates a slug from the name before validation" do
      new_trend = Trend.new(name: "Ruby 3.4 Release", centroid_embedding: Array.new(768, 0.1), first_observed_at: Time.current, last_observed_at: Time.current)
      expect(new_trend).to be_valid
      expect(new_trend.slug).to eq("ruby-3-4-release")
    end

    it "registers #purge as an after_commit callback" do
      callback_names = Trend._commit_callbacks.select { |cb| cb.kind == :after }.map(&:filter)
      expect(callback_names).to include(:purge)
    end

    it "registers #purge_all as an after_commit callback" do
      callback_names = Trend._commit_callbacks.select { |cb| cb.kind == :after }.map(&:filter)
      expect(callback_names).to include(:purge_all)
    end
  end

  describe "#purge" do
    it "purges the record key via Fastly if configured" do
      trend = build(:trend)
      fastly_double = instance_double(Fastly)
      service_double = double

      allow(Trend).to receive(:fastly).and_return(fastly_double)
      allow(Trend).to receive(:service).and_return(service_double)

      expect(service_double).to receive(:purge_by_key).with(trend.record_key)
      trend.purge
    end
  end

  describe "#purge_all" do
    it "purges the table key via Fastly if configured" do
      trend = build(:trend)
      fastly_double = instance_double(Fastly)
      service_double = double

      allow(Trend).to receive(:fastly).and_return(fastly_double)
      allow(Trend).to receive(:service).and_return(service_double)

      expect(service_double).to receive(:purge_by_key).with(Trend.table_key)
      trend.purge_all
    end
  end

  describe "scopes" do
    describe ".hot_and_recent" do
      it "returns active trends within the last 7 days ordered by score descending" do
        trend_low = create(:trend, score: 2.0, last_observed_at: 1.day.ago)
        trend_high = create(:trend, score: 20.0, last_observed_at: 2.days.ago)
        trend_old = create(:trend, score: 50.0, last_observed_at: 8.days.ago)

        expect(Trend.hot_and_recent.to_a).to eq([trend_high, trend_low])
        expect(Trend.hot_and_recent.to_a).not_to include(trend_old)
      end
    end
  end
end
