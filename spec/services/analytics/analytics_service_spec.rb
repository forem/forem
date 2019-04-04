require "rails_helper"

RSpec.describe AnalyticsService, type: :service do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }

  describe "#totals" do
    it "returns totals stats for a user" do
      totals = described_class.new(user).totals
      expect(totals.keys).to eq(%i[comments reactions follows page_views])
    end

    it "returns stats for comments for a user" do
      totals = described_class.new(user).totals
      expect(totals[:comments].keys).to eq([:total])
    end

    it "returns stats for reactions for a user" do
      totals = described_class.new(user).totals
      expect(totals[:reactions].keys).to eq(%i[total like readinglist unicorn])
    end

    it "returns stats for follows for a user" do
      totals = described_class.new(user).totals
      expect(totals[:follows].keys).to eq([:total])
    end

    it "returns stats for page views for a user" do
      totals = described_class.new(user).totals
      expect(totals[:page_views].keys).to eq(%i[total average_read_time_in_seconds total_read_time_in_seconds])
    end

    it "returns totals stats for an org" do
      totals = described_class.new(organization).totals
      expect(totals.keys).to eq(%i[comments reactions follows page_views])
    end
  end

  describe "#stats_grouped_by_day" do
    it "returns stats grouped by day" do
      stats = described_class.new(user, start: "2019-04-01", end: "2019-04-04").stats_grouped_by_day
      expect(stats.keys).to eq(["Mon, 04/01", "Tue, 04/02", "Wed, 04/03", "Thu, 04/04"])
    end

    it "returns stats for a specific day" do
      stats = described_class.new(user, start: "2019-04-01", end: "2019-04-04").stats_grouped_by_day
      expect(stats["Mon, 04/01"].keys).to eq(%i[comments reactions page_views follows])
    end
  end
end
