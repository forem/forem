require "rails_helper"

RSpec.describe Admin::StatsData do
  describe "#call" do
    before do
      # Clean up to avoid test pollution
      Article.delete_all
      Comment.delete_all
      Reaction.delete_all
      User.delete_all
    end

    it "returns stats for the specified period" do
      # Create a shared user for all content to avoid inflating user count
      user = create(:user, registered_at: 10.days.ago)
      
      article1 = create(:article, :past, past_published_at: 3.days.ago, user: user)
      article2 = create(:article, :past, past_published_at: 5.days.ago, user: user)
      article3 = create(:article, :past, past_published_at: 10.days.ago, user: user)
      create(:comment, commentable: article1, created_at: 2.days.ago, user: user)
      create(:comment, commentable: article3, created_at: 12.days.ago, user: user)
      create(:reaction, reactable: article2, created_at: 4.days.ago, user: user)
      
      # Create a new user within the time period
      create(:user, registered_at: 1.day.ago)

      stats = described_class.new(7).call

      expect(stats[:published_posts]).to eq(2)
      expect(stats[:comments]).to eq(1)
      expect(stats[:public_reactions]).to eq(1)
      expect(stats[:new_users]).to eq(1)
      expect(stats[:period]).to eq(7)
    end

    it "returns stats for 30 days" do
      create(:article, :past, past_published_at: 15.days.ago)
      create(:article, :past, past_published_at: 35.days.ago)

      stats = described_class.new(30).call

      expect(stats[:published_posts]).to eq(1)
      expect(stats[:period]).to eq(30)
    end

    it "returns stats for 90 days" do
      create(:article, :past, past_published_at: 50.days.ago)
      create(:article, :past, past_published_at: 100.days.ago)

      stats = described_class.new(90).call

      expect(stats[:published_posts]).to eq(1)
      expect(stats[:period]).to eq(90)
    end

    it "defaults to 7 days if no period is specified" do
      stats = described_class.new.call

      expect(stats[:period]).to eq(7)
    end

    it "includes data from the start of the period to now" do
      # Create article at exactly 7 days ago (beginning of day)
      create(:article, :past, past_published_at: 7.days.ago.beginning_of_day)
      # Create article at 8 days ago (should not be included)
      create(:article, :past, past_published_at: 8.days.ago)

      stats = described_class.new(7).call

      expect(stats[:published_posts]).to eq(1)
    end

    it "counts only public reactions" do
      article = create(:article)
      # Create public reaction
      create(:reaction, reactable: article, created_at: 2.days.ago, category: "like")
      # Create another public reaction
      create(:reaction, reactable: article, created_at: 3.days.ago, category: "unicorn")

      stats = described_class.new(7).call

      expect(stats[:public_reactions]).to eq(2)
    end
  end
end

