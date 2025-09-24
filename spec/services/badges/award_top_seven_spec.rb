require "rails_helper"

RSpec.describe Badges::AwardTopSeven, type: :service do
  let(:badge) { create(:badge, title: "Top 7") }
  let(:user) { create(:user, reputation_modifier: 1.0) }
  let(:other_user) { create(:user, reputation_modifier: 1.5) }

  describe ".call" do
    before do
      # Ensure the badge is created before running tests
      badge
    end

    context "when awarding badges" do
      it "awards top seven badge to users" do
        expect do
          described_class.call([user.username, other_user.username])
        end.to change(BadgeAchievement, :count).by(2)
      end

      it "creates badge achievements for the correct users" do
        described_class.call([user.username, other_user.username])
        
        expect(BadgeAchievement.where(user: user, badge: badge)).to exist
        expect(BadgeAchievement.where(user: other_user, badge: badge)).to exist
      end
    end

    context "when applying reputation modifier changes" do
      let(:badge_recipient) { create(:user, reputation_modifier: 1.0) }
      let(:article) { create(:article, user: badge_recipient, created_at: 3.days.ago) }
      let(:positive_reactor1) { create(:user, reputation_modifier: 1.0) }
      let(:positive_reactor2) { create(:user, reputation_modifier: 2.0) }
      let(:negative_reactor) { create(:user, :trusted, reputation_modifier: 1.0) }

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
          described_class.call([badge_recipient.username])
        end.to change { badge_recipient.reload.reputation_modifier }.from(1.0).to(2.0)
      end

      it "caps the badge recipient's reputation modifier at 4.0" do
        badge_recipient.update!(reputation_modifier: 3.0)
        
        expect do
          described_class.call([badge_recipient.username])
        end.to change { badge_recipient.reload.reputation_modifier }.from(3.0).to(4.0)
      end

      it "multiplies positive reactors' reputation modifiers by 1.5" do
        expect do
          described_class.call([badge_recipient.username])
        end.to change { positive_reactor1.reload.reputation_modifier }.from(1.0).to(1.5)
      end

      it "caps positive reactors' reputation modifiers at 4.0" do
        positive_reactor2.update!(reputation_modifier: 3.0)
        
        expect do
          described_class.call([badge_recipient.username])
        end.to change { positive_reactor2.reload.reputation_modifier }.from(3.0).to(4.0)
      end

      it "does not affect users who gave negative reactions" do
        expect do
          described_class.call([badge_recipient.username])
        end.not_to change { negative_reactor.reload.reputation_modifier }
      end

      it "only considers reactions from the last week" do
        old_article = create(:article, user: badge_recipient, created_at: 2.weeks.ago)
        old_reactor = create(:user, reputation_modifier: 1.0)
        create(:reaction, user: old_reactor, reactable: old_article, category: "like")
        
        expect do
          described_class.call([badge_recipient.username])
        end.not_to change { old_reactor.reload.reputation_modifier }
      end

      it "handles multiple badge recipients independently" do
        second_recipient = create(:user, reputation_modifier: 1.0)
        second_article = create(:article, user: second_recipient, created_at: 3.days.ago)
        second_reactor = create(:user, reputation_modifier: 1.0)
        create(:reaction, user: second_reactor, reactable: second_article, category: "like")
        
        expect do
          described_class.call([badge_recipient.username, second_recipient.username])
        end.to change { badge_recipient.reload.reputation_modifier }.from(1.0).to(2.0)
        .and change { second_recipient.reload.reputation_modifier }.from(1.0).to(2.0)
        .and change { positive_reactor1.reload.reputation_modifier }.from(1.0).to(1.5)
        .and change { second_reactor.reload.reputation_modifier }.from(1.0).to(1.5)
      end

      it "logs the reputation modifier changes" do
        allow(Rails.logger).to receive(:info)
        
        described_class.call([badge_recipient.username])
        
        expect(Rails.logger).to have_received(:info).with(
          "Applied reputation modifier changes for Top 7 badge recipient: #{badge_recipient.username}"
        )
        expect(Rails.logger).to have_received(:info).with(
          "Updated 2 positive reactors' reputation modifiers"
        )
      end
    end

    context "when no positive reactions exist" do
      let(:badge_recipient) { create(:user, reputation_modifier: 1.0) }
      let(:article) { create(:article, user: badge_recipient, created_at: 3.days.ago) }

      it "still doubles the badge recipient's reputation modifier" do
        expect do
          described_class.call([badge_recipient.username])
        end.to change { badge_recipient.reload.reputation_modifier }.from(1.0).to(2.0)
      end

      it "logs zero positive reactors" do
        allow(Rails.logger).to receive(:info)
        
        described_class.call([badge_recipient.username])
        
        expect(Rails.logger).to have_received(:info).with(
          "Updated 0 positive reactors' reputation modifiers"
        )
      end
    end

    context "when user has no articles" do
      let(:badge_recipient) { create(:user, reputation_modifier: 1.0) }

      it "still doubles the badge recipient's reputation modifier" do
        expect do
          described_class.call([badge_recipient.username])
        end.to change { badge_recipient.reload.reputation_modifier }.from(1.0).to(2.0)
      end
    end

    context "when reputation modifier is already at maximum" do
      let(:badge_recipient) { create(:user, reputation_modifier: 4.0) }
      let(:article) { create(:article, user: badge_recipient, created_at: 3.days.ago) }
      let(:positive_reactor) { create(:user, reputation_modifier: 4.0) }

      before do
        create(:reaction, user: positive_reactor, reactable: article, category: "like")
      end

      it "does not change reputation modifiers that are already at maximum" do
        expect do
          described_class.call([badge_recipient.username])
        end.not_to change { badge_recipient.reload.reputation_modifier }
        
        expect do
          described_class.call([badge_recipient.username])
        end.not_to change { positive_reactor.reload.reputation_modifier }
      end
    end

    context "when using custom message markdown" do
      let(:custom_message) { "Custom congratulations message!" }

      it "uses the custom message" do
        allow(Badges::Award).to receive(:call)
        
        described_class.call([user.username], custom_message)
        
        expect(Badges::Award).to have_received(:call).with(
          anything, anything, custom_message
        )
      end
    end
  end

  describe ".default_message_markdown" do
    it "returns the default message" do
      expect(described_class.default_message_markdown).to eq(
        I18n.t("services.badges.congrats", community: Settings::Community.community_name)
      )
    end
  end
end
