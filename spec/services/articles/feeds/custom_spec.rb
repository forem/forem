require "rails_helper"

RSpec.describe Articles::Feeds::Custom, type: :service do
  # In test environment, TIME_AGO_MAX is 90.days.ago.
  let(:user) { create(:user) }
  # Stub feed_config to return a string rather than a Proc.
  let(:feed_config) { build(:feed_config) }
  before do
    allow(feed_config).to receive(:score_sql).with(user).and_return("articles.score")
  end

  # Create articles that are published within the allowed time window.
  let!(:high_score_article) do
    a = create(:article, published: true, score: 100)
    a.update_column(:published_at, Time.current - 1.day)
    a
  end

  let!(:medium_score_article) do
    a = create(:article, published: true, score: 50)
    a.update_column(:published_at, Time.current - 2.days)
    a
  end

  let!(:low_score_article) do
    a = create(:article, published: true, score: 10)
    a.update_column(:published_at, Time.current - 3.days)
    a
  end

  # Create an article published outside of the allowed window.
  let!(:old_article) do
    a = create(:article, published: true, score: 80)
    a.update_column(:published_at, Time.current - 100.days)
    a
  end

  subject(:feed) do
    described_class.new(
      user: user,
      number_of_articles: 100,
      page: 1,
      feed_config: feed_config
    )
  end

  describe "#default_home_feed" do
    context "when feed_config or user is nil" do
      it "returns an empty array if feed_config is nil" do
        feed_with_nil_config = described_class.new(user: user, feed_config: nil)
        expect(feed_with_nil_config.default_home_feed).to eq([])
      end

      it "returns an empty array if user is nil" do
        feed_with_nil_user = described_class.new(user: nil, feed_config: feed_config)
        expect(feed_with_nil_user.default_home_feed).to eq([])
      end
    end

    context "when valid feed_config and user are provided" do
      it "returns only articles published after TIME_AGO_MAX sorted by computed score descending" do
        result = feed.default_home_feed.to_a

        # Articles older than TIME_AGO_MAX (90 days) should be excluded.
        expect(result).to include(high_score_article, medium_score_article, low_score_article)
        expect(result).not_to include(old_article)

        # Since computed_score equals articles.score, the feed should be ordered by score descending.
        expect(result).to eq([high_score_article, medium_score_article, low_score_article])
      end

      it "applies pagination via limit and offset" do
        # Create extra articles so that we can test pagination.
        30.times do
          a = create(:article, published: true, score: 20)
          a.update_column(:published_at, Time.current - 1.day)
        end

        paged_feed = described_class.new(
          user: user,
          number_of_articles: 2,
          page: 2,
          feed_config: feed_config
        )
        result = paged_feed.default_home_feed.to_a
        expect(result.size).to eq(2)
      end

      it "filters out blocked articles" do
        blocked_user = create(:user)
        a = create(:article, published: true, score: 90, user: blocked_user)
        a.update_column(:published_at, Time.current - 1.day)
        create(:user_block, blocker: user, blocked: blocked_user, config: "default")
        result = feed.default_home_feed.to_a
        expect(result).not_to include(a)
      end

      context "when user has antifollowed tags" do
        let!(:hidden_article) do
          a = create(:article, published: true, score: 70, tags: "hidden")
          a.update_column(:published_at, Time.current - 1.day)
          a
        end

        let!(:visible_article) do
          a = create(:article, published: true, score: 60, tags: "visible")
          a.update_column(:published_at, Time.current - 1.day)
          a
        end

        before do
          # Stub the user's antifollowed tags.
          allow(user).to receive(:cached_antifollowed_tag_names).and_return(["hidden"])
        end

        it "excludes articles tagged with antifollowed tags" do
          result = feed.default_home_feed.to_a
          expect(result).not_to include(hidden_article)
          expect(result).to include(visible_article)
        end
      end
    end
  end

  describe "public interface aliases" do
    it "aliases feed to default_home_feed" do
      expect(feed.method(:feed)).to eq(feed.method(:default_home_feed))
    end

    it "aliases more_comments_minimal_weight_randomized to default_home_feed" do
      expect(feed.method(:more_comments_minimal_weight_randomized))
        .to eq(feed.method(:default_home_feed))
    end
  end
end
