require "rails_helper"

RSpec.describe Moderations::ArticleFetcherService do
  let(:user) { create(:user, :trusted) }
  let(:service) { described_class.new(user: user, feed: "inbox", members: "all") }

  describe "#call" do
    before do
      # Create some test articles with different scores
      create_list(:published_article, 3, user: create(:user)) # These will have default scores
      
      # Create articles with low scores (below minimum threshold)
      2.times do
        article = create(:published_article, user: create(:user))
        article.update_column(:score, -10) # Below MINIMUM_ARTICLE_SCORE (-5)
      end
    end

    it "returns JSON string of articles" do
      result = service.call
      expect(result).to be_a(String)
      
      parsed_result = JSON.parse(result)
      expect(parsed_result).to be_an(Array)
    end

    it "excludes articles with scores below minimum threshold" do
      result = service.call
      parsed_result = JSON.parse(result)
      
      # Should only include articles with score >= MINIMUM_ARTICLE_SCORE (-5)
      expect(parsed_result.length).to eq(3)
    end

    context "with different parameters" do
      let(:tag) { create(:tag) }
      let(:service_with_tag) { described_class.new(user: user, feed: "latest", members: "new", tag: tag.name) }

      it "returns different results for different parameters" do
        result1 = service.call
        result2 = service_with_tag.call
        
        expect(result1).not_to eq(result2)
      end
    end
  end

  describe "filtering logic" do
    it "filters by minimum score threshold" do
      # Create articles with different scores
      high_score_article = create(:published_article, user: create(:user))
      high_score_article.update_column(:score, 10)
      
      low_score_article = create(:published_article, user: create(:user))
      low_score_article.update_column(:score, -10)
      
      # Use "latest" feed to avoid inbox filtering
      latest_service = described_class.new(user: user, feed: "latest", members: "all")
      result = latest_service.call
      parsed_result = JSON.parse(result)
      
      # Should only include the high score article
      expect(parsed_result.length).to eq(1)
      expect(parsed_result.first["id"]).to eq(high_score_article.id)
    end

    it "filters by feed lookback period" do
      # Create a recent article
      recent_article = create(:published_article, user: create(:user))
      recent_article.update_column(:published_at, 5.days.ago)
      
      # Create an old article (outside feed lookback period)
      old_article = create(:published_article, user: create(:user))
      old_article.update_column(:published_at, 15.days.ago)
      
      # Mock the feed lookback setting to 10 days
      allow(Settings::UserExperience).to receive(:feed_lookback_days).and_return(10)
      
      latest_service = described_class.new(user: user, feed: "latest", members: "all")
      result = latest_service.call
      parsed_result = JSON.parse(result)
      
      # Should only include the recent article
      expect(parsed_result.length).to eq(1)
      expect(parsed_result.first["id"]).to eq(recent_article.id)
      expect(parsed_result.map { |a| a["id"] }).not_to include(old_article.id)
    end
  end
end
