require "rails_helper"

RSpec.describe Badges::AwardThumbsUp, type: :service do
  let(:thumbs_up_tiers) { described_class::THUMBS_UP_BADGES.keys }
  let(:user) { create(:user) }

  it "does nothing if there are no thumbsup badges" do
    allow(described_class).to receive(:get_user_thumbsup_counts).and_return(user.id => thumbs_up_tiers.max)

    expect { described_class.call }.not_to change { user.badges.count }
  end

  context "when there are thumbsup badges" do
    let!(:all_badges) do
      described_class::THUMBS_UP_BADGES.map do |_, badge_title|
        create(:badge, title: badge_title)
      end
    end
    let(:min_badge) { Badge.find_by(title: described_class::THUMBS_UP_BADGES[thumbs_up_tiers.min]) }
    let(:ghost_user) { create(:user) }
    let(:prolific_user) { create(:user) }

    it "awards the correct badge to the correct user" do
      allow(described_class).to receive(:get_user_thumbsup_counts)
        .and_return(user.id => thumbs_up_tiers.min, prolific_user.id => thumbs_up_tiers.max)
      described_class.call
      expect(ghost_user.badges.count).to eq(0)
      expect(user.badges).to eq([min_badge])
      expect(prolific_user.badges).to eq(all_badges)
    end

    it "doesn't award badges second time" do
      create(:badge_achievement, user: user, badge: min_badge)
      allow(described_class).to receive(:get_user_thumbsup_counts).and_return(user.id => thumbs_up_tiers.min + 1)
      expect do
        described_class.call
      end.not_to change(user.badge_achievements, :count)
    end

    describe ".get_user_thumbsup_counts and .backfill" do
      let(:recent_article_ids) { (1..100).to_a }
      let(:other_article_ids) { (101..105).to_a }

      def insert_thumbsup_reactions(target_user, article_ids, created_at:)
        now = Time.current
        rows = article_ids.map do |article_id|
          {
            user_id: target_user.id,
            reactable_id: article_id,
            reactable_type: "Article",
            category: "thumbsup",
            points: 1.0,
            status: "valid",
            created_at: created_at,
            updated_at: now
          }
        end
        Reaction.insert_all!(rows)
        target_user.update_column(:reactions_count, target_user.reactions_count + rows.size)
      end

      it "aggregates recent Article thumbsup reactions and skips out-of-window or under-threshold users" do
        insert_thumbsup_reactions(prolific_user, recent_article_ids, created_at: 1.day.ago)
        insert_thumbsup_reactions(user, other_article_ids, created_at: 1.day.ago)
        insert_thumbsup_reactions(ghost_user, recent_article_ids, created_at: 10.days.ago)

        counts = described_class.get_user_thumbsup_counts
        expect(counts).to eq(prolific_user.id => 100)
      end

      it "backfills historical users who missed the incremental lookback window" do
        insert_thumbsup_reactions(prolific_user, recent_article_ids, created_at: 10.days.ago)

        expect do
          described_class.backfill
        end.to change { prolific_user.reload.badges.count }.by(1)

        expect(prolific_user.badges).to contain_exactly(min_badge)
      end
    end
  end
end
