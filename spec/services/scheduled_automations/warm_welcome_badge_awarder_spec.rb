require "rails_helper"

RSpec.describe ScheduledAutomations::WarmWelcomeBadgeAwarder, type: :service do
  let(:bot) { create(:user, type_of: :community_bot) }
  let(:admin_user) { create(:user, :super_admin) }
  let(:badge) { create(:badge, slug: "warm-welcome", title: "Warm Welcome", allow_multiple_awards: true) }
  let(:welcome_thread) do
    create(:article, :past,
           user: admin_user,
           published: true,
           past_published_at: 2.weeks.ago,
           tag_list: "welcome",
           title: "Welcome Thread")
  end
  let(:automation) do
    create(:scheduled_automation,
           user: bot,
           service_name: "warm_welcome_badge",
           action: "award_warm_welcome_badge",
           action_config: {},
           frequency: "weekly",
           frequency_config: { "day_of_week" => 5, "hour" => 9, "minute" => 0 },
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

    context "when badge does not exist" do
      before do
        badge.destroy
      end

      it "returns a failure result" do
        result = awarder.call
        expect(result.success?).to be(false)
        expect(result.error_message).to include("Badge with slug 'warm-welcome' not found")
        expect(result.users_awarded).to eq(0)
      end
    end

    context "when welcome thread does not exist" do
      before do
        welcome_thread.destroy
      end

      it "returns success with zero users awarded" do
        result = awarder.call
        expect(result.success?).to be(true)
        expect(result.users_awarded).to eq(0)
      end
    end

    context "when welcome thread exists" do
      let(:user1) { create(:user) }
      let(:user2) { create(:user) }
      let(:user3) { create(:user) }

      before do
        automation.update!(last_run_at: nil)
      end

      context "with helpful comments" do
        let!(:helpful_comment1) do
          create(:comment,
                 user: user1,
                 commentable: welcome_thread,
                 body_markdown: "Welcome to the community! Here are some tips to get started...",
                 created_at: 2.days.ago,
                 score: 10)
        end
        let!(:helpful_comment2) do
          create(:comment,
                 user: user2,
                 commentable: welcome_thread,
                 body_markdown: "Great to have you here! Feel free to ask any questions.",
                 created_at: 1.day.ago,
                 score: 5)
        end

        before do
          # Mock AI assessments
          allow_any_instance_of(Ai::CommentCheck).to receive(:spam?).and_return(false)
          allow_any_instance_of(Ai::CommentHelpfulnessAssessor).to receive(:helpful?).and_return(true)
        end

        it "awards badges to users with helpful comments" do
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
          expect(achievement.rewarding_context_message_markdown).to include("Welcome Thread")
          expect(achievement.rewarding_context_message_markdown).to include("helpful comment")
        end
      end

      context "with spam comments" do
        let!(:spam_comment) do
          create(:comment,
                 user: user1,
                 commentable: welcome_thread,
                 body_markdown: "Check out my website: http://spam.com",
                 created_at: 2.days.ago,
                 score: -10)
        end

        before do
          allow_any_instance_of(Ai::CommentCheck).to receive(:spam?).and_return(true)
        end

        it "does not award badges for spam comments" do
          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(0)
          expect(user1.badge_achievements.where(badge: badge).count).to eq(0)
        end
      end

      context "with low quality comments" do
        let!(:low_quality_comment) do
          create(:comment,
                 user: user1,
                 commentable: welcome_thread,
                 body_markdown: "test",
                 created_at: 2.days.ago,
                 score: -100)
        end

        before do
          allow_any_instance_of(Ai::CommentCheck).to receive(:spam?).and_return(false)
        end

        it "does not award badges for low quality comments" do
          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(0)
          expect(user1.badge_achievements.where(badge: badge).count).to eq(0)
        end
      end

      context "with unhelpful comments" do
        let!(:unhelpful_comment) do
          create(:comment,
                 user: user1,
                 commentable: welcome_thread,
                 body_markdown: "ok",
                 created_at: 2.days.ago,
                 score: 0)
        end

        before do
          allow_any_instance_of(Ai::CommentCheck).to receive(:spam?).and_return(false)
          allow_any_instance_of(Ai::CommentHelpfulnessAssessor).to receive(:helpful?).and_return(false)
        end

        it "does not award badges for unhelpful comments" do
          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(0)
          expect(user1.badge_achievements.where(badge: badge).count).to eq(0)
        end
      end

      context "with comments outside the lookback window" do
        let!(:old_comment) do
          create(:comment,
                 user: user1,
                 commentable: welcome_thread,
                 body_markdown: "Welcome!",
                 created_at: 10.days.ago,
                 score: 10)
        end

        before do
          allow_any_instance_of(Ai::CommentCheck).to receive(:spam?).and_return(false)
          allow_any_instance_of(Ai::CommentHelpfulnessAssessor).to receive(:helpful?).and_return(true)
        end

        it "does not award badges for comments outside the lookback window" do
          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(0)
          expect(user1.badge_achievements.where(badge: badge).count).to eq(0)
        end
      end

      context "with comments before last_run_at" do
        let!(:old_comment) do
          create(:comment,
                 user: user1,
                 commentable: welcome_thread,
                 body_markdown: "Welcome!",
                 created_at: 5.days.ago,
                 score: 10)
        end

        before do
          automation.update!(last_run_at: 3.days.ago)
          allow_any_instance_of(Ai::CommentCheck).to receive(:spam?).and_return(false)
          allow_any_instance_of(Ai::CommentHelpfulnessAssessor).to receive(:helpful?).and_return(true)
        end

        it "does not award badges for comments before last_run_at" do
          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(0)
          expect(user1.badge_achievements.where(badge: badge).count).to eq(0)
        end
      end

      context "with recently awarded users" do
        let!(:helpful_comment) do
          create(:comment,
                 user: user1,
                 commentable: welcome_thread,
                 body_markdown: "Welcome to the community!",
                 created_at: 2.days.ago,
                 score: 10)
        end

        before do
          # User already received badge 3 days ago (within 6.5 days)
          create(:badge_achievement,
                 user: user1,
                 badge: badge,
                 created_at: 3.days.ago)
          allow_any_instance_of(Ai::CommentCheck).to receive(:spam?).and_return(false)
          allow_any_instance_of(Ai::CommentHelpfulnessAssessor).to receive(:helpful?).and_return(true)
        end

        it "does not award badges to users who received it within the last 6.5 days" do
          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(0)
          expect(user1.badge_achievements.where(badge: badge).count).to eq(1)
        end
      end

      context "with users who received badge more than 6.5 days ago" do
        let!(:helpful_comment) do
          create(:comment,
                 user: user1,
                 commentable: welcome_thread,
                 body_markdown: "Welcome to the community!",
                 created_at: 2.days.ago,
                 score: 10)
        end

        before do
          # User received badge 7 days ago (more than 6.5 days)
          create(:badge_achievement,
                 user: user1,
                 badge: badge,
                 created_at: 7.days.ago)
          allow_any_instance_of(Ai::CommentCheck).to receive(:spam?).and_return(false)
          allow_any_instance_of(Ai::CommentHelpfulnessAssessor).to receive(:helpful?).and_return(true)
        end

        it "allows awarding badge again after 6.5 days" do
          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(1)
          expect(user1.badge_achievements.where(badge: badge).count).to eq(2)
        end
      end

      context "with deleted comments" do
        let!(:deleted_comment) do
          create(:comment,
                 user: user1,
                 commentable: welcome_thread,
                 body_markdown: "Welcome!",
                 created_at: 2.days.ago,
                 score: 10,
                 deleted: true)
        end

        before do
          allow_any_instance_of(Ai::CommentCheck).to receive(:spam?).and_return(false)
          allow_any_instance_of(Ai::CommentHelpfulnessAssessor).to receive(:helpful?).and_return(true)
        end

        it "does not award badges for deleted comments" do
          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(0)
          expect(user1.badge_achievements.where(badge: badge).count).to eq(0)
        end
      end

      context "with banished users" do
        let(:banished_user) { create(:user, username: "spam_#{rand(1_000_000)}") }
        let!(:comment) do
          create(:comment,
                 user: banished_user,
                 commentable: welcome_thread,
                 body_markdown: "Welcome!",
                 created_at: 2.days.ago,
                 score: 10)
        end

        before do
          allow_any_instance_of(Ai::CommentCheck).to receive(:spam?).and_return(false)
          allow_any_instance_of(Ai::CommentHelpfulnessAssessor).to receive(:helpful?).and_return(true)
        end

        it "does not award badges to banished users" do
          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(0)
          expect(banished_user.badge_achievements.where(badge: badge).count).to eq(0)
        end
      end

      context "with multiple comments from same user" do
        let!(:comment1) do
          create(:comment,
                 user: user1,
                 commentable: welcome_thread,
                 body_markdown: "Welcome!",
                 created_at: 3.days.ago,
                 score: 10)
        end
        let!(:comment2) do
          create(:comment,
                 user: user1,
                 commentable: welcome_thread,
                 body_markdown: "Great to have you!",
                 created_at: 2.days.ago,
                 score: 5)
        end

        before do
          allow_any_instance_of(Ai::CommentCheck).to receive(:spam?).and_return(false)
          allow_any_instance_of(Ai::CommentHelpfulnessAssessor).to receive(:helpful?).and_return(true)
        end

        it "awards badge only once per user" do
          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(1)
          expect(user1.badge_achievements.where(badge: badge).count).to eq(1)
        end
      end

      context "with reply comments" do
        let(:parent_comment) do
          create(:comment,
                 user: user2,
                 commentable: welcome_thread,
                 body_markdown: "I'm new here!",
                 created_at: 5.days.ago)
        end
        let!(:helpful_reply) do
          create(:comment,
                 user: user1,
                 commentable: welcome_thread,
                 parent: parent_comment,
                 body_markdown: "Welcome! Here's how to get started...",
                 created_at: 2.days.ago,
                 score: 10)
        end

        before do
          allow_any_instance_of(Ai::CommentCheck).to receive(:spam?).and_return(false)
          allow_any_instance_of(Ai::CommentHelpfulnessAssessor).to receive(:helpful?).and_return(true)
        end

        it "awards badges for helpful reply comments" do
          result = awarder.call

          expect(result.success?).to be(true)
          expect(result.users_awarded).to eq(1)
          expect(user1.badge_achievements.where(badge: badge).count).to eq(1)
        end
      end

      context "when an error occurs" do
        before do
          # Ensure badge exists so we get past the badge check
          badge
          # Then raise error when finding welcome thread
          allow_any_instance_of(described_class).to receive(:find_current_welcome_thread).and_raise(StandardError, "Database error")
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
end

