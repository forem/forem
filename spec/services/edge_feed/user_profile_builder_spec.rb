require "rails_helper"

RSpec.describe EdgeFeed::UserProfileBuilder, type: :service do
  let(:user) { create(:user, :without_profile, profile_image: nil) }
  let(:now) { Time.zone.at(1_750_000_000) }

  describe "#build" do
    it "serializes user activity, filters, settings, targeting bucket, and precomputed selections" do
      create(
        :user_activity,
        user: user,
        alltime_users: [10, 20],
        recent_users: [30],
        alltime_organizations: [40],
        recent_organizations: [50],
        alltime_subforems: [1],
        recent_subforems: [1, 2, 1],
        recent_tags: %w[rust wasm],
        alltime_tags: %w[ruby],
        recent_labels: %w[deep-dive],
        recently_viewed_articles: [[101, (now - 1.hour).iso8601, 45]],
      )
      user.setting.update!(feed_ai_preference: :minimize_ai)
      RecommendedArticlesList.create!(
        user: user,
        name: "Test Recommendations",
        placement_area: :main_feed,
        article_ids: [101, 202],
        expires_at: now + 1.day,
      )
      allow(UserBlock).to receive(:cached_blocked_ids_for_blocker).with(user.id).and_return([999])
      allow(user).to receive_messages(
        cached_antifollowed_tag_names: ["crypto"],
        cached_languages: %w[en fr],
      )

      profile = described_class.new(user: user, now: now).build

      expect(profile).to include(
        user_id: user.id,
        has_activity_store: true,
        blocked_user_ids: [999],
        hidden_tags: ["crypto"],
        hide_fully_autonomous: false,
        ai_preference: 1,
        languages: %w[en fr],
        alltime_users: [10, 20],
        alltime_users_from_activity: true,
        recent_users: [30],
        alltime_organizations: [40],
        recent_organizations: [50],
        alltime_subforems: [1],
        recent_subforems: [1, 2, 1],
        recent_tags: %w[rust wasm],
        alltime_tags: %w[ruby],
        recent_labels: %w[deep-dive],
        recently_viewed_articles: [[101, (now - 1.hour).to_i]],
        precomputed_selections: [101, 202],
      )
      expect(FeedConfig::FEED_TARGETING_BUCKETS).to include(profile[:targeting_bucket])
    end
  end
end
