require "rails_helper"

RSpec.describe AnalyticsService, type: :service do
  let(:user) { create(:user) }
  let(:second_user) { create(:user) }
  let(:article) { create(:article, user: second_user) }
  let(:organization) { create(:organization) }

  describe "initialization" do
    it "raises an error if start date is invalid" do
      expect(-> { described_class.new(user, start_date: "2000-") }).to raise_error(ArgumentError)
    end

    it "raises an error if end date is invalid" do
      expect(-> { described_class.new(user, end_date: "2000-") }).to raise_error(ArgumentError)
    end

    it "raises an error if an article id is invalid" do
      expect(-> { described_class.new(user, single_article_id: article.id) }).to raise_error(UnauthorizedError)
    end
  end

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
    before do
      article = create(:article, user: user, published: true)
      create(:reaction, reactable: article)
      create(:reading_reaction, reactable: article)
      create(:page_view, user: user, article: article)
      create(:follow)
    end

    it "returns stats grouped by day" do
      stats = described_class.new(user, start_date: "2019-04-01", end_date: "2019-04-04").stats_grouped_by_day
      expect(stats.keys).to eq(["2019-04-01", "2019-04-02", "2019-04-03", "2019-04-04"])
    end

    it "returns stats for a specific day" do
      stats = described_class.new(user, start_date: "2019-04-01", end_date: "2019-04-04").stats_grouped_by_day
      expect(stats["2019-04-01"].keys).to eq(%i[comments reactions page_views follows])
    end
  end
end
