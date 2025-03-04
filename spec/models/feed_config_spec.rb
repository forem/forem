require "rails_helper"

RSpec.describe FeedConfig, type: :model do
  subject(:feed_config) { described_class.create! }  # Ensure it is persisted

  let(:user) do
    double("User",
      id: 1,
      cached_following_users_ids: [10, 20],
      cached_following_organizations_ids: [100, 200],
      cached_followed_tag_names: ["tech", "ruby"],
      languages: double("Languages", pluck: ["en"]),
      # page_views stub for original tests; not used for additional weights
      page_views: double("PageViews", order: double("Ordered", second: double("PageView", created_at: Time.current - 1.day))),
      user_activity: nil
    )
  end

  before do
    allow(RecommendedArticlesList).to receive_message_chain(:where, :where, :last, :article_ids).and_return([])
  end

  describe "#score_sql" do
    context "when all base weights are positive" do
      before do
        feed_config.feed_success_weight           = 1.0
        feed_config.comment_score_weight          = 2.0
        feed_config.score_weight                  = 3.0
        feed_config.organization_follow_weight    = 4.0
        feed_config.user_follow_weight            = 5.0
        feed_config.tag_follow_weight             = 6.0
        feed_config.recency_weight                = 7.0
        feed_config.comment_recency_weight        = 8.0
        feed_config.lookback_window_weight        = 9.0
        feed_config.precomputed_selections_weight = 10.0
      end

      it "includes all the expected SQL fragments" do
        sql = feed_config.score_sql(user)
        expect(sql).to include("articles.feed_success_score * 1.0")
        expect(sql).to include("articles.comment_score * 2.0")
        expect(sql).to include("articles.score * 3.0")
        expect(sql).to include("CASE WHEN articles.organization_id IN")
        expect(sql).to include("CASE WHEN articles.user_id IN")
        expect(sql).to include("cached_tag_list")
        expect(sql).to include("EXTRACT(epoch FROM (NOW() - articles.published_at))")
        expect(sql).to include("EXTRACT(epoch FROM (NOW() - articles.last_comment_at))")
        expect(sql).to include("CASE WHEN articles.published_at BETWEEN")
      end
    end

    context "when some base weights are zero" do
      before do
        feed_config.feed_success_weight           = 1.0
        feed_config.comment_score_weight          = 0.0
        feed_config.score_weight                  = 3.0
        feed_config.organization_follow_weight    = 0.0
        feed_config.user_follow_weight            = 5.0
        feed_config.tag_follow_weight             = 0.0
        feed_config.recency_weight                = 7.0
        feed_config.comment_recency_weight        = 0.0
        feed_config.lookback_window_weight        = 9.0
        feed_config.precomputed_selections_weight = 0.0
      end

      it "skips SQL terms for weights that are zero" do
        sql = feed_config.score_sql(user)
        expect(sql).to include("articles.feed_success_score * 1.0")
        expect(sql).not_to include("articles.comment_score *")
        expect(sql).to include("articles.score * 3.0")
        expect(sql).not_to include("organization_id IN")
        expect(sql).to include("CASE WHEN articles.user_id IN")
        expect(sql).not_to include("cached_tag_list")
        expect(sql).to include("EXTRACT(epoch FROM (NOW() - articles.published_at))")
        expect(sql).not_to include("EXTRACT(epoch FROM (NOW() - articles.last_comment_at))")
        expect(sql).to include("CASE WHEN articles.published_at BETWEEN")
        expect(sql).not_to include("articles.id IN (")
      end
    end

    context "when all base weights are zero" do
      before do
        feed_config.feed_success_weight           = 0.0
        feed_config.comment_score_weight          = 0.0
        feed_config.score_weight                  = 0.0
        feed_config.organization_follow_weight    = 0.0
        feed_config.user_follow_weight            = 0.0
        feed_config.tag_follow_weight             = 0.0
        feed_config.recency_weight                = 0.0
        feed_config.comment_recency_weight        = 0.0
        feed_config.lookback_window_weight        = 0.0
        feed_config.precomputed_selections_weight = 0.0
      end

      it "returns 0 as the SQL expression" do
        expect(feed_config.score_sql(user)).to eq("(0)")
      end
    end

    context "when additional weights are positive" do
      let(:recently_viewed_articles) { [[101, Time.current - 1.hour, 30], [102, Time.current - 2.hours, 40]] }
      let(:activity_store) do
        double("ActivityStore",
          recently_viewed_articles: recently_viewed_articles,
          recent_users: [],
          recent_organizations: [],
          relevant_tags: []
        )
      end

      before do
        # Provide a user_activity that includes recently_viewed_articles.
        allow(user).to receive(:user_activity).and_return(activity_store)
        # Set additional weights.
        feed_config.recent_article_suppression_rate = 2.0
        feed_config.published_today_weight         = 3.0
        feed_config.featured_weight                = 4.0
        feed_config.clickbait_score_weight         = 5.0
        feed_config.compellingness_score_weight    = 6.0
        feed_config.language_match_weight          = 7.0
        feed_config.randomness_weight              = 8.0
      end

      it "includes the suppression for recently viewed articles" do
        sql = feed_config.score_sql(user)
        expect(sql).to include("CASE WHEN articles.id IN (101,102)")
        expect(sql).to include("-2.0")
      end

      it "includes the published today weight" do
        sql = feed_config.score_sql(user)
        published_since = 24.hours.ago.utc.to_s(:db)
        expect(sql).to include("articles.published_at >= '#{published_since}'")
        expect(sql).to include("3.0")
      end

      it "includes the featured weight" do
        sql = feed_config.score_sql(user)
        expect(sql).to include("CASE WHEN articles.featured = TRUE THEN 4.0")
      end

      it "includes the clickbait score subtraction" do
        sql = feed_config.score_sql(user)
        expect(sql).to include("- (articles.clickbait_score * 5.0)")
      end

      it "includes the compellingness score" do
        sql = feed_config.score_sql(user)
        expect(sql).to include("articles.compellingness_score * 6.0")
      end

      it "includes the language match weight" do
        sql = feed_config.score_sql(user)
        expect(sql).to include("CASE WHEN articles.language IN ('en') THEN 7.0")
      end

      it "includes the randomness injection" do
        sql = feed_config.score_sql(user)
        expect(sql).to include("RANDOM() * 8.0")
      end
    end
  end

  describe "#create_slightly_modified_clone!" do
    before do
      feed_config.feed_success_weight           = 1.0
      feed_config.comment_score_weight          = 2.0
      feed_config.comment_recency_weight        = 3.0
      feed_config.label_match_weight            = 4.0
      feed_config.lookback_window_weight        = 5.0
      feed_config.organization_follow_weight    = 6.0
      feed_config.precomputed_selections_weight = 7.0
      feed_config.recency_weight                = 8.0
      feed_config.score_weight                  = 9.0
      feed_config.tag_follow_weight             = 10.0
      feed_config.user_follow_weight            = 11.0

      feed_config.randomness_weight              = 12.0
      feed_config.recent_article_suppression_rate = 13.0
      feed_config.published_today_weight         = 14.0
      feed_config.featured_weight                = 15.0
      feed_config.clickbait_score_weight         = 16.0
      feed_config.compellingness_score_weight    = 17.0
      feed_config.language_match_weight          = 18.0

      # Stub rand to return 0.1 for a deterministic 10% increase.
      allow(feed_config).to receive(:rand).and_return(0.1)
    end

    it "creates a persisted clone with adjusted weights" do
      expect { feed_config.create_slightly_modified_clone! }
        .to change { FeedConfig.count }.by(1)

      clone = FeedConfig.last

      expect(clone.persisted?).to be true
      expect(clone.feed_success_weight).to eq(1.0 * 1.1)
      expect(clone.comment_score_weight).to eq(2.0 * 1.1)
      expect(clone.comment_recency_weight).to eq(3.0 * 1.1)
      expect(clone.label_match_weight).to eq(4.0 * 1.1)
      expect(clone.lookback_window_weight).to eq(5.0 * 1.1)
      expect(clone.organization_follow_weight).to eq(6.0 * 1.1)
      expect(clone.precomputed_selections_weight).to eq(7.0 * 1.1)
      expect(clone.recency_weight).to eq(8.0 * 1.1)
      expect(clone.score_weight).to eq(9.0 * 1.1)
      expect(clone.tag_follow_weight).to eq(10.0 * 1.1)
      expect(clone.user_follow_weight).to eq(11.0 * 1.1)
      expect(clone.randomness_weight).to eq(12.0 * 1.1)
      expect(clone.recent_article_suppression_rate).to eq(13.0 * 1.1)
      expect(clone.published_today_weight).to eq(14.0 * 1.1)
      expect(clone.featured_weight).to eq(15.0 * 1.1)
      expect(clone.clickbait_score_weight).to eq(16.0 * 1.1)
      expect(clone.compellingness_score_weight).to eq(17.0 * 1.1)
      expect(clone.language_match_weight).to eq(18.0 * 1.1)
    end

    it "does not modify the original feed_config" do
      original_attributes = feed_config.reload.attributes.slice(
        "feed_success_weight", "comment_score_weight", "comment_recency_weight",
        "label_match_weight", "lookback_window_weight", "organization_follow_weight",
        "precomputed_selections_weight", "recency_weight", "score_weight",
        "tag_follow_weight", "user_follow_weight", "randomness_weight",
        "recent_article_suppression_rate", "published_today_weight", "featured_weight",
        "clickbait_score_weight", "compellingness_score_weight", "language_match_weight"
      )

      feed_config.create_slightly_modified_clone!

      # Reload the original feed_config to verify it hasn't changed.
      expect(feed_config.reload.attributes.slice(*original_attributes.keys)).to eq(original_attributes)
    end
  end
end
