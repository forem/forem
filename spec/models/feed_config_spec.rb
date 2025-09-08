require "rails_helper"

RSpec.describe FeedConfig, type: :model do
  subject(:feed_config) { described_class.create! }

  let(:cached_followed_tag_names) { ["tech", "ruby"] }

  let(:activity_store) do
    double("ActivityStore",
      recently_viewed_articles: [],
      recent_users: [],
      recent_organizations: [],
      relevant_tags: ["tech", "ruby"],
      recent_labels: ["label1"],
      recent_subforems: [1],
      alltime_users: [10, 20],
      alltime_organizations: [100, 200],
      alltime_subforems: [30, 40] # Added for subforem follow testing
    )
  end

  let(:user) do
    double("User",
      id: 1,
      cached_following_users_ids: [10, 20],
      cached_following_organizations_ids: [100, 200],
      cached_followed_tag_names: ["tech", "ruby"],
      languages: double("Languages", pluck: ["en"]),
      page_views: double("PageViews", order: double("Ordered", second: double("PageView", created_at: Time.current - 1.day))),
      user_activity: activity_store
    )
  end

  before do
    allow(RecommendedArticlesList)
      .to receive_message_chain(:where, :where, :last, :article_ids)
      .and_return([])
  end

  describe "#score_sql" do
    context "when tag_follow_weight is positive and tag count configs present" do
      before do
        feed_config.tag_follow_weight      = 6.0
        feed_config.recent_tag_count_min   = 2
        feed_config.recent_tag_count_max   = 2
        feed_config.all_time_tag_count_min = 3
        feed_config.all_time_tag_count_max = 3
        allow(activity_store)
          .to receive(:relevant_tags)
          .with(2, 3)
          .and_return(["tagX", "tagY"])
      end

      it "invokes relevant_tags with configured counts and includes returned tags" do
        sql = feed_config.score_sql(user)
        expect(activity_store).to have_received(:relevant_tags).with(2, 3)
        expect(sql).to include("articles.cached_tag_list ~ '[[:<:]]tagX[[:>:]]'")
        expect(sql).to include("articles.cached_tag_list ~ '[[:<:]]tagY[[:>:]]'")
      end
    end

    context "when tag_follow_weight is positive but no tag count configs" do
      before do
        feed_config.tag_follow_weight      = 6.0
        feed_config.recent_tag_count_min   = 0
        feed_config.recent_tag_count_max   = 0
        feed_config.all_time_tag_count_min = 0
        feed_config.all_time_tag_count_max = 0
        # Stub relevant_tags to return nil so fallback is used
        allow(activity_store)
          .to receive(:relevant_tags)
          .with(5, 5)
          .and_return(nil)
      end

      it "falls back to user's cached_followed_tag_names" do
        sql = feed_config.score_sql(user)
        expect(activity_store).to have_received(:relevant_tags).with(5, 5)
        cached_followed_tag_names.each do |tag|
          expect(sql).to include("articles.cached_tag_list ~ '[[:<:]]#{tag}[[:>:]]'")
        end
      end
    end

    context "when all base weights are positive" do
      before do
        feed_config.feed_success_weight           = 1.0
        feed_config.comment_score_weight          = 2.0
        feed_config.score_weight                  = 3.0
        feed_config.organization_follow_weight    = 4.0
        feed_config.user_follow_weight            = 5.0
        feed_config.tag_follow_weight             = 6.0
        feed_config.label_match_weight            = 4.0
        feed_config.recency_weight                = 7.0
        feed_config.comment_recency_weight        = 8.0
        feed_config.lookback_window_weight        = 9.0
        feed_config.precomputed_selections_weight = 10.0
        feed_config.subforem_follow_weight        = 11.0

        subforem = create(:subforem, domain: "#{rand(10_000)}.com")
        root_subforem = create(:subforem, domain: "#{rand(10_000)}.com")
        allow(RequestStore).to receive(:store).and_return(
          subforem_id: root_subforem.id,
          default_subforem_id: root_subforem.id,
          root_subforem_id: root_subforem.id
        )
      end

      it "includes all the expected SQL fragments including label and subforem matching" do
        sql = feed_config.score_sql(user)
        expect(sql).to include("articles.feed_success_score * 1.0")
        expect(sql).to include("articles.comment_score * 2.0")
        expect(sql).to include("articles.score * 3.0")
        expect(sql).to include("CASE WHEN articles.organization_id IN")
        expect(sql).to include("CASE WHEN articles.user_id IN")
        expect(sql).to include("cached_tag_list")
        expect(sql).to include("articles.cached_label_list")
        expect(sql).to include("EXTRACT(epoch FROM (NOW() - articles.published_at))")
        expect(sql).to include("EXTRACT(epoch FROM (NOW() - articles.last_comment_at))")
        expect(sql).to include("CASE WHEN articles.published_at BETWEEN")
        expect(sql).to include("CASE WHEN articles.subforem_id IN (30,40) THEN 11.0") # Added expectation
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
        feed_config.label_match_weight            = 0.0
        feed_config.recency_weight                = 7.0
        feed_config.comment_recency_weight        = 0.0
        feed_config.lookback_window_weight        = 9.0
        feed_config.precomputed_selections_weight = 0.0
        feed_config.subforem_follow_weight        = 0.0 # Added new weight
      end

      it "skips SQL terms for weights that are zero including labels and subforems" do
        sql = feed_config.score_sql(user)
        expect(sql).to include("articles.feed_success_score * 1.0")
        expect(sql).not_to include("articles.comment_score *")
        expect(sql).to include("articles.score * 3.0")
        expect(sql).not_to include("organization_id IN")
        expect(sql).to include("CASE WHEN articles.user_id IN")
        expect(sql).not_to include("cached_tag_list")
        expect(sql).not_to include("cached_label_list")
        expect(sql).to include("EXTRACT(epoch FROM (NOW() - articles.published_at))")
        expect(sql).not_to include("EXTRACT(epoch FROM (NOW() - articles.last_comment_at))")
        expect(sql).to include("CASE WHEN articles.published_at BETWEEN")
        expect(sql).not_to include("articles.id IN (")
        expect(sql).not_to include("subforem_id IN") # Added expectation
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
        feed_config.label_match_weight            = 0.0
        feed_config.recency_weight                = 0.0
        feed_config.comment_recency_weight        = 0.0
        feed_config.lookback_window_weight        = 0.0
        feed_config.precomputed_selections_weight = 0.0
        feed_config.subforem_follow_weight        = 0.0 # Added new weight
      end

      it "returns 0 as the SQL expression" do
        expect(feed_config.score_sql(user)).to eq("(0)")
      end
    end

    context "when additional weights are positive" do
      let(:recently_viewed_articles) { [[101, Time.current - 1.hour], [102, Time.current - 2.hours]] }
      let(:activity_store) do
        double("ActivityStore",
          recently_viewed_articles: recently_viewed_articles,
          recent_users: [],
          recent_organizations: [],
          relevant_tags: [],
          recent_labels: [],
          recent_subforems: [1],
          alltime_users: [10, 20],
          alltime_organizations: [100, 200],
          alltime_subforems: [30, 40]
        )
      end

      before do
        allow(user).to receive(:user_activity).and_return(activity_store)
        feed_config.recent_article_suppression_rate = 2.0
        feed_config.published_today_weight         = 3.0
        feed_config.featured_weight                = 4.0
        feed_config.clickbait_score_weight         = 5.0
        feed_config.compellingness_score_weight    = 6.0
        feed_config.language_match_weight          = 7.0
        feed_config.randomness_weight              = 8.0
        feed_config.recent_subforem_weight         = 0.5
        feed_config.general_past_day_bonus_weight      = 9.0
        feed_config.recently_active_past_day_bonus_weight = 1.5
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

      it "includes the general past day bonus weight" do
        sql = feed_config.score_sql(user)
        published_since = 24.hours.ago.utc.to_s(:db)
        expect(sql).to include("articles.published_at >= '#{published_since}'")
        expect(sql).to include("THEN 9.0")
      end

      it "includes the recently active past day bonus weight" do
        sql = feed_config.score_sql(user)
        published_since = 24.hours.ago.utc.to_s(:db)
        # 2 recent pageviews in `let(:recently_viewed_articles)`
        bonus = 1.5 * 2
        expect(sql).to include("articles.published_at >= '#{published_since}'")
        expect(sql).to include("THEN #{bonus.to_f}")
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

      it "includes the recent subforem weight if request is root" do
        subforem = create(:subforem, domain: "#{rand(10_000)}.com")
        root_subforem = create(:subforem, domain: "#{rand(10_000)}.com")
        allow(RequestStore).to receive(:store).and_return(
          subforem_id: root_subforem.id,
          default_subforem_id: root_subforem.id,
          root_subforem_id: root_subforem.id
        )
        sql = feed_config.score_sql(user)
        expect(sql).to include("CASE WHEN articles.subforem_id = ANY(ARRAY[1]::bigint[])")
      end

      it "does not include recent subforem weight if request is not root" do
        subforem = create(:subforem, domain: "#{rand(10_000)}.com")
        default_subforem = create(:subforem, domain: "#{rand(10_000)}.com")
        root_subforem = create(:subforem, domain: "#{rand(10_000)}.com")
        allow(RequestStore).to receive(:store).and_return(
          subforem_id: subforem.id,
          default_subforem_id: default_subforem.id,
          root_subforem_id: root_subforem.id
        )
        sql = feed_config.score_sql(user)
        expect(sql).not_to include("CASE WHEN articles.subforem_id = ANY(ARRAY[1]::bigint[])")
      end
    end

    context "when recently active bonus is positive but user has no recent views" do
      let(:activity_store) do
        double("ActivityStore", recently_viewed_articles: [], recent_users: [], recent_organizations: [],
                                relevant_tags: [], recent_labels: [], recent_subforems: [],
                                alltime_users: [], alltime_organizations: [], alltime_subforems: [])
      end

      before do
        # Turn off all other weights to isolate the test
        described_class.new.attributes.each_key do |attr|
          feed_config[attr] = 0.0 if attr.ends_with?("_weight") || attr.ends_with?("_rate")
        end
        feed_config.recently_active_past_day_bonus_weight = 1.5
      end

      it "does not add the bonus term" do
        expect(feed_config.score_sql(user)).to eq("(0)")
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
      feed_config.randomness_weight             = 12.0
      feed_config.recent_article_suppression_rate = 13.0
      feed_config.published_today_weight         = 14.0
      feed_config.featured_weight                = 15.0
      feed_config.clickbait_score_weight         = 16.0
      feed_config.compellingness_score_weight    = 17.0
      feed_config.language_match_weight          = 18.0
      feed_config.general_past_day_bonus_weight = 19.0
      feed_config.recently_active_past_day_bonus_weight = 20.0
      feed_config.subforem_follow_weight        = 21.0 # Added new weight
      feed_config.recent_page_views_shuffle_weight = 22.0
      feed_config.recent_tag_count_min           = 2
      feed_config.recent_tag_count_max           = 5
      feed_config.all_time_tag_count_min         = 3
      feed_config.all_time_tag_count_max         = 8

      allow(feed_config).to receive(:rand).with(0.9..1.1).and_return(1.1)
      allow(feed_config).to receive(:rand).with(-1..1).and_return(1)
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
      expect(clone.general_past_day_bonus_weight).to eq(19.0 * 1.1)
      expect(clone.recently_active_past_day_bonus_weight).to eq(20.0 * 1.1)
      expect(clone.subforem_follow_weight).to eq(21.0 * 1.1) # Added expectation
      expect(clone.recent_page_views_shuffle_weight).to eq(22.0 * 1.1)
    end

    it "does not modify the original feed_config" do
      original_attrs = feed_config.reload.attributes.slice(
        "feed_success_weight",
        "comment_score_weight",
        "comment_recency_weight",
        "label_match_weight",
        "lookback_window_weight",
        "organization_follow_weight",
        "precomputed_selections_weight",
        "recency_weight",
        "score_weight",
        "tag_follow_weight",
        "user_follow_weight",
        "randomness_weight",
        "recent_article_suppression_rate",
        "published_today_weight",
        "general_past_day_bonus_weight",
        "recently_active_past_day_bonus_weight",
        "featured_weight",
        "clickbait_score_weight",
        "compellingness_score_weight",
        "language_match_weight",
        "subforem_follow_weight", # Added new weight to check
        "recent_page_views_shuffle_weight",
        "recent_tag_count_min",
        "recent_tag_count_max",
        "all_time_tag_count_min",
        "all_time_tag_count_max"
      )

      feed_config.create_slightly_modified_clone!

      expect(feed_config.reload.attributes.slice(*original_attrs.keys)).to eq(original_attrs)
    end

    it "adjusts tag count ranges with +/- offsets and resets impressions" do
      feed_config.create_slightly_modified_clone!
      clone = FeedConfig.last

      expect(clone.recent_tag_count_min).to eq(3)
      expect(clone.recent_tag_count_max).to eq(6)
      expect(clone.all_time_tag_count_min).to eq(4)
      expect(clone.all_time_tag_count_max).to eq(9)
      expect(clone.feed_impressions_count).to eq(0)
    end
  end
end