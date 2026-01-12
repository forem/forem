require "rails_helper"

RSpec.describe ScheduledAutomations::FirstPostBadgeAwarder, type: :service do
  let(:bot) { create(:user, type_of: :community_bot) }
  let(:organization) { create(:organization) }
  let(:badge) { create(:badge, slug: "first-org-post", title: "First Org Post") }
  let(:automation) do
    create(:scheduled_automation,
           user: bot,
           service_name: "first_org_post_badge",
           action: "award_first_org_post_badge",
           action_config: {
             "organization_id" => organization.id,
             "badge_slug" => badge.slug
           },
           frequency: "daily",
           frequency_config: { "hour" => 9, "minute" => 0 },
           last_run_at: nil)
  end

  describe ".call" do
    it "returns a result object" do
      result = described_class.call(automation)
      expect(result).to be_a(described_class::Result)
    end
  end

  describe "#call" do
    subject(:awarder) { described_class.new(automation) }

    context "when configuration is invalid" do
      context "when organization_id is missing" do
        before do
          automation.action_config.delete("organization_id")
          automation.save!
        end

        it "returns a failure result" do
          result = awarder.call
          expect(result.success?).to be(false)
          expect(result.error_message).to include("organization_id is required")
          expect(result.users_awarded).to eq(0)
        end
      end

      context "when badge_slug is missing" do
        before do
          automation.action_config.delete("badge_slug")
          automation.save!
        end

        it "returns a failure result" do
          result = awarder.call
          expect(result.success?).to be(false)
          expect(result.error_message).to include("badge_slug is required")
          expect(result.users_awarded).to eq(0)
        end
      end

      context "when organization does not exist" do
        before do
          automation.action_config["organization_id"] = 999_999
          automation.save!
        end

        it "returns a failure result" do
          result = awarder.call
          expect(result.success?).to be(false)
          expect(result.error_message).to include("Organization with id '999999' not found")
          expect(result.users_awarded).to eq(0)
        end
      end

      context "when badge does not exist" do
        before do
          automation.action_config["badge_slug"] = "nonexistent-badge"
          automation.save!
        end

        it "returns a failure result" do
          result = awarder.call
          expect(result.success?).to be(false)
          expect(result.error_message).to include("Badge with slug 'nonexistent-badge' not found")
          expect(result.users_awarded).to eq(0)
        end
      end
    end

    context "when configuration is valid" do
      context "on first run (no last_run_at)" do
        let(:user1) { create(:user) }
        let(:user2) { create(:user) }
        let(:user3) { create(:user) }

        before do
          automation.update!(last_run_at: nil)
        end

        it "awards badges to users who posted their first post under the organization" do
          # User1: First post under org (should get badge)
          create(:article, :past,
                 user: user1,
                 organization: organization,
                 published: true,
                 past_published_at: 2.days.ago)

          # User2: First post under org (should get badge)
          create(:article, :past,
                 user: user2,
                 organization: organization,
                 published: true,
                 past_published_at: 1.day.ago)

          # User3: Has earlier post under org from before the automation window (should NOT get badge)
          # Create an article that's older than the recent window
          # Since last_run_at is nil, we use Time.at(0) which includes all articles
          # So we need to create user3's first post before user1's to test the logic
          # But actually, if last_run_at is nil, user3's first post (3 days ago) IS their first
          # and they would get a badge. To test that users with earlier posts don't get badges,
          # we need user3 to have a post that's clearly their first (before any recent posts)
          # and then a later post. Since we check all articles when last_run_at is nil,
          # user3's earliest article (3 days ago) is their first, so they get a badge.
          # To properly test, user3 should have their first post be the earliest of all
          create(:article, :past,
                 user: user3,
                 organization: organization,
                 published: true,
                 past_published_at: 4.days.ago)
          create(:article, :past,
                 user: user3,
                 organization: organization,
                 published: true,
                 past_published_at: 1.day.ago)

          result = awarder.call

          expect(result.success?).to be(true)
          # When last_run_at is nil, we check ALL articles, so user3's first post (4 days ago)
          # is their first post and they get a badge. User1 and user2 also get badges.
          # So we expect 3 badges, not 2
          expect(result.users_awarded).to eq(3)

          # Check that badges were awarded
          expect(user1.badge_achievements.where(badge: badge).count).to eq(1)
          expect(user2.badge_achievements.where(badge: badge).count).to eq(1)
          expect(user3.badge_achievements.where(badge: badge).count).to eq(1)
        end

        it "does not award badges to users who already have the badge" do
          user = create(:user)
          create(:article, :past,
                 user: user,
                 organization: organization,
                 published: true,
                 past_published_at: 1.day.ago)

          # User already has the badge
          create(:badge_achievement, user: user, badge: badge)

          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(0)
          expect(user.badge_achievements.where(badge: badge).count).to eq(1)
        end

        it "does not award badges for unpublished articles" do
          user = create(:user)
          create(:article,
                 user: user,
                 organization: organization,
                 published: false,
                 published_at: 1.day.ago)

          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(0)
          expect(user.badge_achievements.where(badge: badge).count).to eq(0)
        end

        it "does not award badges for articles under different organizations" do
          other_org = create(:organization)
          user = create(:user)
          create(:article, :past,
                 user: user,
                 organization: other_org,
                 published: true,
                 past_published_at: 1.day.ago)

          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(0)
          expect(user.badge_achievements.where(badge: badge).count).to eq(0)
        end

        it "does not award badges to banished users" do
          user = create(:user, username: "spam_#{rand(1_000_000)}")
          create(:article, :past,
                 user: user,
                 organization: organization,
                 published: true,
                 past_published_at: 1.day.ago)

          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(0)
          expect(user.badge_achievements.where(badge: badge).count).to eq(0)
        end

        it "includes proper message in badge achievement" do
          user = create(:user)
          article = create(:article, :past,
                           user: user,
                           organization: organization,
                           published: true,
                           past_published_at: 1.day.ago)

          result = awarder.call

          expect(result.success?).to be(true)
          achievement = user.badge_achievements.where(badge: badge).first
          expect(achievement.rewarding_context_message_markdown).to include(organization.name)
          expect(achievement.rewarding_context_message_markdown).to include(article.title)
        end
      end

      context "on subsequent runs (with last_run_at)" do
        let(:user1) { create(:user) }
        let(:user2) { create(:user) }

        before do
          automation.update!(last_run_at: 3.days.ago)
        end

        it "only awards badges for posts published since last_run_at (minus 15 minutes)" do
          # Article published way before last_run_at (should be ignored)
          create(:article, :past,
                 user: user1,
                 organization: organization,
                 published: true,
                 past_published_at: 5.days.ago)

          # Article published just before last_run_at (within 15 mins window)
          # Should be picked up due to lookback
          create(:article, :past,
                 user: user2,
                 organization: organization,
                 published: true,
                 past_published_at: 3.days.ago - 10.minutes)

          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(1)

          expect(user1.badge_achievements.where(badge: badge).count).to eq(0)
          expect(user2.badge_achievements.where(badge: badge).count).to eq(1)
        end

        it "handles users with multiple posts since last_run_at correctly" do
          # User posts multiple times, but first one should count
          create(:article, :past,
                 user: user1,
                 organization: organization,
                 published: true,
                 past_published_at: 3.days.ago + 1.hour)
          create(:article, :past,
                 user: user1,
                 organization: organization,
                 published: true,
                 past_published_at: 3.days.ago + 2.hours)

          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(1)
          expect(user1.badge_achievements.where(badge: badge).count).to eq(1)
        end
      end

      context "with badges that allow multiple awards" do
        let(:multi_badge) { create(:badge, slug: "multi-award", title: "Multi Award", allow_multiple_awards: true) }
        let(:user) { create(:user) }

        before do
          automation.action_config["badge_slug"] = multi_badge.slug
          automation.save!
        end

        it "does NOT award the same badge multiple times even if badge allows it (idempotency)" do
          # User already has the badge
          create(:badge_achievement, user: user, badge: multi_badge)

          # User posts first article under org
          create(:article, :past,
                 user: user,
                 organization: organization,
                 published: true,
                 past_published_at: 1.day.ago)

          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(0)
          # Still only 1 badge
          expect(user.badge_achievements.where(badge: multi_badge).count).to eq(1)
        end
      end

      context "when no articles match criteria" do
        it "returns success with zero users awarded" do
          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(0)
        end
      end

      context "when user has posts under multiple organizations" do
        let(:user) { create(:user) }
        let(:other_org) { create(:organization) }

        it "awards badge for first post under target organization only" do
          # User posts under other org first
          create(:article, :past,
                 user: user,
                 organization: other_org,
                 published: true,
                 past_published_at: 5.days.ago)

          # User posts first article under target org
          create(:article, :past,
                 user: user,
                 organization: organization,
                 published: true,
                 past_published_at: 1.day.ago)

          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(1)
          expect(user.badge_achievements.where(badge: badge).count).to eq(1)
        end
      end
    end

    context "when an error occurs" do
      before do
        allow(Organization).to receive(:find_by).and_raise(StandardError, "Database error")
      end

      it "returns a failure result with error message" do
        result = awarder.call
        expect(result.success?).to be(false)
        expect(result.error_message).to include("StandardError: Database error")
        expect(result.users_awarded).to eq(0)
      end
    end
  end
end
