require "rails_helper"

RSpec.describe BadgeAchievement do
  let(:badge_with_credits) { create(:badge, credits_awarded: 10) }
  let(:badge) { create(:badge, credits_awarded: 0) }
  let(:achievement) { create(:badge_achievement, badge: badge) }
  let(:credits_achievement) { create(:badge_achievement, badge: badge_with_credits) }

  describe "validations" do
    describe "builtin validations" do
      subject { achievement }

      it { is_expected.to belong_to(:user) }
      it { is_expected.to belong_to(:badge) }
      it { is_expected.to belong_to(:rewarder).class_name("User").optional }
      it { is_expected.to validate_uniqueness_of(:badge_id).scoped_to(:user_id) }
    end
  end

  it "turns rewarding_context_message_markdown into rewarding_context_message HTML" do
    expect(achievement.rewarding_context_message).to include("</a>")
  end

  it "doesn't award credits if credits_awarded is zero" do
    expect(achievement.user.credits.size).to eq(0)
  end

  it "awards credits after create if credits_awarded exist" do
    expect(credits_achievement.user.credits.size).to eq(10)
  end

  it "notifies recipients after commit" do
    achievement
    allow(Notification).to receive(:send_new_badge_achievement_notification)
    achievement.run_callbacks(:commit)
    expect(Notification).to have_received(:send_new_badge_achievement_notification).with(achievement)
  end

  describe "Top 7 badge reputation modifier callback" do
    let(:top_seven_badge) { create(:badge, title: "Top 7") }
    let(:other_badge) { create(:badge, title: "Other Badge") }
    let(:user) { create(:user, reputation_modifier: 1.0) }
    let(:article) { create(:article, user: user, created_at: 3.days.ago) }
    let(:positive_reactor1) { create(:user, reputation_modifier: 1.0) }
    let(:positive_reactor2) { create(:user, reputation_modifier: 2.0) }
    let(:negative_reactor) { create(:user, :trusted, reputation_modifier: 1.0) }

    before do
      # Ensure the badge is created with correct slug
      top_seven_badge
      other_badge
    end

    context "when creating a Top 7 badge achievement" do
      before do
        # Create positive reactions
        create(:reaction, user: positive_reactor1, reactable: article, category: "like")
        create(:reaction, user: positive_reactor2, reactable: article, category: "unicorn")
        create(:reaction, user: positive_reactor1, reactable: article, category: "fire")
        
        # Create negative reaction (should not be affected)
        create(:vomit_reaction, user: negative_reactor, reactable: article)
      end

      it "doubles the badge recipient's reputation modifier" do
        expect do
          create(:badge_achievement, user: user, badge: top_seven_badge)
        end.to change { user.reload.reputation_modifier }.from(1.0).to(2.0)
      end

      it "caps the badge recipient's reputation modifier at 4.0" do
        user.update!(reputation_modifier: 3.0)
        
        expect do
          create(:badge_achievement, user: user, badge: top_seven_badge)
        end.to change { user.reload.reputation_modifier }.from(3.0).to(4.0)
      end

      it "multiplies positive reactors' reputation modifiers by 1.5" do
        expect do
          create(:badge_achievement, user: user, badge: top_seven_badge)
        end.to change { positive_reactor1.reload.reputation_modifier }.from(1.0).to(1.5)
      end

      it "caps positive reactors' reputation modifiers at 4.0" do
        positive_reactor2.update!(reputation_modifier: 3.0)
        
        expect do
          create(:badge_achievement, user: user, badge: top_seven_badge)
        end.to change { positive_reactor2.reload.reputation_modifier }.from(3.0).to(4.0)
      end

      it "does not affect users who gave negative reactions" do
        expect do
          create(:badge_achievement, user: user, badge: top_seven_badge)
        end.not_to change { negative_reactor.reload.reputation_modifier }
      end

      it "only considers reactions from the last week" do
        old_article = create(:article, user: user, created_at: 2.weeks.ago)
        old_reactor = create(:user, reputation_modifier: 1.0)
        create(:reaction, user: old_reactor, reactable: old_article, category: "like")
        
        expect do
          create(:badge_achievement, user: user, badge: top_seven_badge)
        end.not_to change { old_reactor.reload.reputation_modifier }
      end

      it "logs the reputation modifier changes" do
        allow(Rails.logger).to receive(:info)
        
        create(:badge_achievement, user: user, badge: top_seven_badge)
        
        expect(Rails.logger).to have_received(:info).with(
          "Applied reputation modifier changes for Top 7 badge recipient: #{user.username}"
        )
        expect(Rails.logger).to have_received(:info).with(
          "Updated 2 positive reactors' reputation modifiers"
        )
      end
    end

    context "when creating a non-Top 7 badge achievement" do
      it "does not change reputation modifiers" do
        expect do
          create(:badge_achievement, user: user, badge: other_badge)
        end.not_to change { user.reload.reputation_modifier }
      end

      it "does not log reputation modifier changes" do
        allow(Rails.logger).to receive(:info)
        
        create(:badge_achievement, user: user, badge: other_badge)
        
        expect(Rails.logger).not_to have_received(:info).with(
          /Applied reputation modifier changes for Top 7 badge recipient/
        )
      end
    end

    context "when user has no articles" do
      it "still doubles the badge recipient's reputation modifier" do
        expect do
          create(:badge_achievement, user: user, badge: top_seven_badge)
        end.to change { user.reload.reputation_modifier }.from(1.0).to(2.0)
      end

      it "logs zero positive reactors" do
        allow(Rails.logger).to receive(:info)
        
        create(:badge_achievement, user: user, badge: top_seven_badge)
        
        expect(Rails.logger).to have_received(:info).with(
          "Updated 0 positive reactors' reputation modifiers"
        )
      end
    end

    context "when reputation modifier is already at maximum" do
      let(:user_at_max) { create(:user, reputation_modifier: 4.0) }
      let(:reactor_at_max) { create(:user, reputation_modifier: 4.0) }
      let(:article_at_max) { create(:article, user: user_at_max, created_at: 3.days.ago) }

      before do
        create(:reaction, user: reactor_at_max, reactable: article_at_max, category: "like")
      end

      it "does not change user reputation modifier when already at maximum" do
        expect do
          create(:badge_achievement, user: user_at_max, badge: top_seven_badge)
        end.not_to change { user_at_max.reload.reputation_modifier }
      end

      it "does not change reactor reputation modifier when already at maximum" do
        expect do
          create(:badge_achievement, user: user_at_max, badge: top_seven_badge)
        end.not_to change { reactor_at_max.reload.reputation_modifier }
      end
    end

    context "when no positive reactions exist" do
      it "still doubles the badge recipient's reputation modifier" do
        expect do
          create(:badge_achievement, user: user, badge: top_seven_badge)
        end.to change { user.reload.reputation_modifier }.from(1.0).to(2.0)
      end

      it "logs zero positive reactors" do
        allow(Rails.logger).to receive(:info)
        
        create(:badge_achievement, user: user, badge: top_seven_badge)
        
        expect(Rails.logger).to have_received(:info).with(
          "Updated 0 positive reactors' reputation modifiers"
        )
      end
    end
  end
end
