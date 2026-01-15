require "rails_helper"

RSpec.describe ScheduledAutomations::ArticleContentBadgeAwarder, type: :service do
  let(:bot) { create(:user, type_of: :community_bot) }
  let(:badge) { create(:badge, slug: "quality-article", title: "Quality Article", allow_multiple_awards: true) }
  let(:automation) do
    create(:scheduled_automation,
           user: bot,
           service_name: "article_content_badge",
           action: "award_article_content_badge",
           action_config: {
             "badge_slug" => "quality-article",
             "keywords" => %w[ruby rails],
             "criteria" => "well-researched technical content",
             "lookback_hours" => 2
           },
           frequency: "hourly",
           frequency_config: { "minute" => 0 },
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

    before do
      badge # Ensure badge exists
      allow(Settings::UserExperience).to receive_messages(
        index_minimum_score: 0,
        index_minimum_date: 1.year.ago.to_i,
      )
    end

    context "when badge does not exist" do
      before do
        badge.destroy
      end

      it "returns a failure result" do
        result = awarder.call
        expect(result.success?).to be(false)
        expect(result.error_message).to include("Badge with slug 'quality-article' not found")
        expect(result.users_awarded).to eq(0)
      end
    end

    context "when badge_slug is missing" do
      before do
        automation.update!(action_config: { "criteria" => "test" })
      end

      it "returns a failure result" do
        result = awarder.call
        expect(result.success?).to be(false)
        expect(result.error_message).to include("badge_slug is required in action_config")
      end
    end

    context "when criteria is missing" do
      before do
        automation.update!(action_config: { "badge_slug" => "quality-article" })
      end

      it "returns a failure result" do
        result = awarder.call
        expect(result.success?).to be(false)
        expect(result.error_message).to include("criteria is required in action_config")
      end
    end

    context "when articles exist" do
      let(:user1) { create(:user) }
      let(:user2) { create(:user) }
      let(:user3) { create(:user) }

      before do
        badge # Ensure badge exists
        automation.update!(last_run_at: nil)
      end

      context "with qualifying articles matching keywords" do
        let!(:article1) do
          create(:published_article, :past,
                 user: user1,
                 title: "Ruby on Rails Tutorial",
                 body_markdown: "Ruby on Rails is a powerful framework...",
                 tag_list: "ruby, rails",
                 past_published_at: 1.hour.ago,
                 score: 10,
                 featured: false)
        end
        let!(:article2) do
          create(:published_article, :past,
                 user: user2,
                 title: "Advanced Rails Patterns",
                 body_markdown: "Rails has many advanced patterns...",
                 tag_list: "rails, ruby",
                 past_published_at: 30.minutes.ago,
                 score: 15,
                 featured: false)
        end

        before do
          allow_any_instance_of(Ai::BadgeCriteriaAssessor).to receive(:qualifies?).and_return(true)
        end

        it "awards badges to users with qualifying articles" do
          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(2)

          expect(user1.badge_achievements.where(badge: badge).count).to eq(1)
          expect(user2.badge_achievements.where(badge: badge).count).to eq(1)
        end

        it "includes proper message in badge achievement" do
          result = awarder.call

          expect(result.success?).to be(true)
          achievement = user1.badge_achievements.where(badge: badge).first
          expect(achievement.rewarding_context_message_markdown).to include(article1.title)
          expect(achievement.rewarding_context_message_markdown).to include("quality article")
        end
      end

      context "with articles that don't match keywords" do
        let!(:article) do
          create(:published_article, :past,
                 user: user1,
                 title: "Python Tutorial",
                 body_markdown: "Python is a great language...",
                 tag_list: "python",
                 past_published_at: 1.hour.ago,
                 score: 10,
                 featured: false)
        end

        before do
          allow_any_instance_of(Ai::BadgeCriteriaAssessor).to receive(:qualifies?).and_return(true)
        end

        it "does not award badges for articles that don't match keywords" do
          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(0)
          expect(user1.badge_achievements.where(badge: badge).count).to eq(0)
        end
      end

      context "with articles below minimum indexable threshold" do
        let!(:article) do
          create(:published_article, :past,
                 user: user1,
                 title: "Ruby Tutorial",
                 body_markdown: "Ruby is great...",
                 tag_list: "ruby",
                 past_published_at: 1.hour.ago,
                 score: -2, # Below -1 threshold
                 featured: false)
        end

        before do
          allow_any_instance_of(Ai::BadgeCriteriaAssessor).to receive(:qualifies?).and_return(true)
        end

        it "does not award badges for articles below minimum threshold" do
          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(0)
          expect(user1.badge_achievements.where(badge: badge).count).to eq(0)
        end
      end

      context "with articles that don't qualify via AI" do
        let!(:article) do
          create(:published_article, :past,
                 user: user1,
                 title: "Ruby Tutorial",
                 body_markdown: "Ruby is great...",
                 tag_list: "ruby",
                 past_published_at: 1.hour.ago,
                 score: 10,
                 featured: false)
        end

        before do
          allow_any_instance_of(Ai::BadgeCriteriaAssessor).to receive(:qualifies?).and_return(false)
        end

        it "does not award badges for articles that don't qualify" do
          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(0)
          expect(user1.badge_achievements.where(badge: badge).count).to eq(0)
        end
      end

      context "with articles outside the lookback window" do
        let!(:article) do
          create(:published_article, :past,
                 user: user1,
                 title: "Ruby Tutorial",
                 body_markdown: "Ruby is great...",
                 tag_list: "ruby",
                 past_published_at: 3.hours.ago, # Outside 2 hour + 15 min window
                 score: 10,
                 featured: false)
        end

        before do
          allow_any_instance_of(Ai::BadgeCriteriaAssessor).to receive(:qualifies?).and_return(true)
        end

        it "does not award badges for articles outside lookback window" do
          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(0)
          expect(user1.badge_achievements.where(badge: badge).count).to eq(0)
        end
      end

      context "with recently awarded users (multiple awards allowed)" do
        let!(:article) do
          create(:published_article, :past,
                 user: user1,
                 title: "Ruby Tutorial",
                 body_markdown: "Ruby is great...",
                 tag_list: "ruby",
                 past_published_at: 1.hour.ago,
                 score: 10,
                 featured: false)
        end

        before do
          # User already received badge 3 days ago (within last week)
          create(:badge_achievement,
                 user: user1,
                 badge: badge,
                 created_at: 3.days.ago)
          allow_any_instance_of(Ai::BadgeCriteriaAssessor).to receive(:qualifies?).and_return(true)
        end

        it "does not award badges to users who received it within the last week" do
          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(0)
          expect(user1.badge_achievements.where(badge: badge).count).to eq(1)
        end
      end

      context "with users who received badge more than a week ago (multiple awards allowed)" do
        let!(:article) do
          create(:published_article, :past,
                 user: user1,
                 title: "Ruby Tutorial",
                 body_markdown: "Ruby is great...",
                 tag_list: "ruby",
                 past_published_at: 1.hour.ago,
                 score: 10,
                 featured: false)
        end

        before do
          # User received badge 8 days ago (more than a week)
          create(:badge_achievement,
                 user: user1,
                 badge: badge,
                 created_at: 8.days.ago)
          allow_any_instance_of(Ai::BadgeCriteriaAssessor).to receive(:qualifies?).and_return(true)
        end

        it "allows awarding badge again after a week" do
          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(1)
          expect(user1.badge_achievements.where(badge: badge).count).to eq(2)
        end
      end

      context "with single award badge" do
        let(:single_award_badge) do
          create(:badge, slug: "single-award", title: "Single Award", allow_multiple_awards: false)
        end
        let(:automation) do
          create(:scheduled_automation,
                 user: bot,
                 service_name: "article_content_badge",
                 action: "award_article_content_badge",
                 action_config: {
                   "badge_slug" => "single-award",
                   "keywords" => ["ruby"],
                   "criteria" => "well-researched technical content"
                 },
                 frequency: "hourly",
                 frequency_config: { "minute" => 0 },
                 last_run_at: nil)
        end

        let!(:article) do
          create(:published_article, :past,
                 user: user1,
                 title: "Ruby Tutorial",
                 body_markdown: "Ruby is great...",
                 tag_list: "ruby",
                 past_published_at: 1.hour.ago,
                 score: 10,
                 featured: false)
        end

        before do
          single_award_badge
          allow_any_instance_of(Ai::BadgeCriteriaAssessor).to receive(:qualifies?).and_return(true)
        end

        context "when user already has the badge" do
          before do
            create(:badge_achievement,
                   user: user1,
                   badge: single_award_badge,
                   created_at: 2.weeks.ago)
          end

          it "does not award badge again" do
            result = awarder.call

            expect(result.success?).to be(true)
            expect(result.users_awarded).to eq(0)
            expect(user1.badge_achievements.where(badge: single_award_badge).count).to eq(1)
          end
        end

        context "when user does not have the badge" do
          it "awards the badge" do
            result = awarder.call

            expect(result.success?).to be(true)
            expect(result.users_awarded).to eq(1)
            expect(user1.badge_achievements.where(badge: single_award_badge).count).to eq(1)
          end
        end
      end

      context "with banished users" do
        let(:banished_user) { create(:user, username: "spam_#{rand(1_000_000)}") }
        let!(:article) do
          create(:published_article, :past,
                 user: banished_user,
                 title: "Ruby Tutorial",
                 body_markdown: "Ruby is great...",
                 tag_list: "ruby",
                 past_published_at: 1.hour.ago,
                 score: 10,
                 featured: false)
        end

        before do
          allow_any_instance_of(Ai::BadgeCriteriaAssessor).to receive(:qualifies?).and_return(true)
        end

        it "does not award badges to banished users" do
          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(0)
          expect(banished_user.badge_achievements.where(badge: badge).count).to eq(0)
        end
      end

      context "with featured articles below minimum score" do
        let!(:article) do
          create(:published_article, :past,
                 user: user1,
                 title: "Ruby Tutorial",
                 body_markdown: "Ruby is great...",
                 tag_list: "ruby",
                 past_published_at: 1.hour.ago,
                 score: 5, # Below minimum but featured
                 featured: true)
        end

        before do
          allow(Settings::UserExperience).to receive(:index_minimum_score).and_return(10)
          allow_any_instance_of(Ai::BadgeCriteriaAssessor).to receive(:qualifies?).and_return(true)
        end

        it "awards badges for featured articles even if below minimum score" do
          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(1)
          expect(user1.badge_achievements.where(badge: badge).count).to eq(1)
        end
      end

      context "with custom lookback hours" do
        let(:automation) do
          create(:scheduled_automation,
                 user: bot,
                 service_name: "article_content_badge",
                 action: "award_article_content_badge",
                 action_config: {
                   "badge_slug" => "quality-article",
                   "keywords" => ["ruby"],
                   "criteria" => "well-researched technical content",
                   "lookback_hours" => 4
                 },
                 frequency: "hourly",
                 frequency_config: { "minute" => 0 },
                 last_run_at: nil)
        end

        let!(:article) do
          create(:published_article, :past,
                 user: user1,
                 title: "Ruby Tutorial",
                 body_markdown: "Ruby is great...",
                 tag_list: "ruby",
                 past_published_at: 3.hours.ago, # Within 4 hour + 15 min window
                 score: 10,
                 featured: false)
        end

        before do
          badge
          allow_any_instance_of(Ai::BadgeCriteriaAssessor).to receive(:qualifies?).and_return(true)
        end

        it "uses custom lookback hours" do
          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(1)
        end
      end

      context "with last_run_at set" do
        let!(:article) do
          create(:published_article, :past,
                 user: user1,
                 title: "Ruby Tutorial",
                 body_markdown: "Ruby is great...",
                 tag_list: "ruby",
                 past_published_at: 1.hour.ago,
                 score: 10,
                 featured: false)
        end

        before do
          automation.update!(last_run_at: 30.minutes.ago)
          allow_any_instance_of(Ai::BadgeCriteriaAssessor).to receive(:qualifies?).and_return(true)
        end

        it "looks back from last_run_at with buffer" do
          result = awarder.call

          expect(result.success?).to be(true)
          # Article was published 1 hour ago, last_run was 30 min ago
          # So we look back 2 hours + 15 min from 30 min ago = 2 hours 45 min ago
          # Article at 1 hour ago should be included
          expect(result.users_awarded).to eq(1)
        end
      end

      context "with no keywords" do
        let(:automation) do
          create(:scheduled_automation,
                 user: bot,
                 service_name: "article_content_badge",
                 action: "award_article_content_badge",
                 action_config: {
                   "badge_slug" => "quality-article",
                   "keywords" => [],
                   "criteria" => "well-researched technical content"
                 },
                 frequency: "hourly",
                 frequency_config: { "minute" => 0 },
                 last_run_at: nil)
        end

        let!(:article) do
          create(:published_article, :past,
                 user: user1,
                 title: "General Tutorial",
                 body_markdown: "This is a great tutorial...",
                 tag_list: "tutorial",
                 past_published_at: 1.hour.ago,
                 score: 10,
                 featured: false)
        end

        before do
          badge
          allow_any_instance_of(Ai::BadgeCriteriaAssessor).to receive(:qualifies?).and_return(true)
        end

        it "processes all articles when no keywords provided" do
          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(1)
        end
      end

      context "when an error occurs" do
        before do
          badge
          allow_any_instance_of(described_class).to receive(:find_candidate_articles).and_raise(StandardError,
                                                                                                "Database error")
        end

        it "returns a failure result with error message" do
          result = awarder.call
          expect(result.success?).to be(false)
          expect(result.error_message).to include("StandardError: Database error")
          expect(result.users_awarded).to eq(0)
        end
      end

      context "with multiple articles from same user" do
        let!(:article1) do
          create(:published_article, :past,
                 user: user1,
                 title: "Ruby Tutorial Part 1",
                 body_markdown: "Ruby is great...",
                 tag_list: "ruby",
                 past_published_at: 1.hour.ago,
                 score: 10,
                 featured: false)
        end
        let!(:article2) do
          create(:published_article, :past,
                 user: user1,
                 title: "Ruby Tutorial Part 2",
                 body_markdown: "More Ruby content...",
                 tag_list: "ruby",
                 past_published_at: 30.minutes.ago,
                 score: 15,
                 featured: false)
        end

        before do
          allow_any_instance_of(Ai::BadgeCriteriaAssessor).to receive(:qualifies?).and_return(true)
        end

        it "awards badge only once per user" do
          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(1)
          expect(user1.badge_achievements.where(badge: badge).count).to eq(1)
        end
      end
    end
  end
end
