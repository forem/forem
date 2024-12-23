require "rails_helper"

RSpec.describe Notifications::Reactions::Send, type: :service do
  let(:user) { create(:user) }
  let(:subforem) { create(:subforem) }
  let(:article) { create(:article, user: user, subforem: subforem) }
  let(:user2) { create(:user) }
  let(:article_reaction) { create(:reaction, reactable: article, user: user2) }
  let(:user3) { create(:user) }

  def reaction_data(reaction)
    Notifications::Reactions::ReactionData.coerce(reaction).to_h
  end

  context "when data is invalid" do
    it "raises an exception" do
      invalid_data = reaction_data(article_reaction).except("reactable_id")
      expect do
        described_class.call(invalid_data, user)
      end.to raise_error(Notifications::Reactions::ReactionData::DataError)
    end
  end

  context "when a reaction is ok" do
    it "creates a notification" do
      expect do
        described_class.call(reaction_data(article_reaction), user)
      end.to change(Notification, :count).by(1)
    end

    it "creates a correct notification" do
      result = described_class.call(reaction_data(article_reaction), user)
      notification = Notification.find(result.notification_id)
      expect(notification.subforem_id).to eq(subforem.id)
      expect(notification.user_id).to eq(user.id)
      expect(notification.notifiable).to eq(article)
    end

    it "creates a notification with the correct json" do
      result = described_class.call(reaction_data(article_reaction), user)
      notification = Notification.find(result.notification_id)
      expect(notification.json_data["user"]["id"]).to eq(user2.id)
      expect(notification.json_data["user"]["name"]).to eq(user2.name)
      expect(notification.json_data["reaction"]["reactable_id"]).to eq(article.id)
      expect(notification.json_data["reaction"]["aggregated_siblings"].size).to eq(1)
    end
  end

  context "when a reaction is persisted and has siblings" do
    before do
      create(:reaction, reactable: article, user: user3, created_at: 1.day.ago)
    end

    it "creates a notification" do
      expect do
        described_class.call(reaction_data(article_reaction), user)
      end.to change(Notification, :count).by(1)
    end

    it "creates a correct notification" do
      result = described_class.call(reaction_data(article_reaction), user)
      notification = Notification.find(result.notification_id)
      expect(notification.notifiable).to eq(article)
      expect(notification.notified_at).not_to be_nil
    end

    it "creates a notification with the correct json" do
      result = described_class.call(reaction_data(article_reaction), user)
      notification = Notification.find(result.notification_id)
      expect(notification.json_data["user"]["id"]).to eq(user2.id)
      expect(notification.json_data["user"]["name"]).to eq(user2.name)
      expect(notification.json_data["reaction"]["reactable_id"]).to eq(article.id)
      expect(notification.json_data["reaction"]["aggregated_siblings"].size).to eq(2)
      expect(notification.json_data["reaction"]["aggregated_siblings"].map do |s|
               s["user"]["id"]
             end.sort).to eq([user2.id, user3.id].sort)
    end

    context "when notification exists" do
      let!(:old_notification) { create(:notification, user: user, notifiable: article, action: "Reaction") }

      before do
        old_notification.update_column(:notified_at, 1.day.ago)
      end

      it "doesn't change notifications count" do
        expect do
          described_class.call(reaction_data(article_reaction), user)
        end.not_to change(Notification, :count)
      end

      it "returns the same notification" do
        result = described_class.call(reaction_data(article_reaction), user)
        notification = Notification.find(result.notification_id)
        expect(notification.id).to eq(old_notification.id)
      end

      it "updates the notification" do
        old_notified_at = old_notification.notified_at
        described_class.call(reaction_data(article_reaction), user)
        old_notification.reload
        expect(old_notification.notified_at).to be > old_notified_at
      end

      it "updates the notification json" do
        described_class.call(reaction_data(article_reaction), user)
        old_notification.reload
        expect(old_notification.json_data["user"]["id"]).to eq(user2.id)
        expect(old_notification.json_data["user"]["name"]).to eq(user2.name)
        expect(old_notification.json_data["reaction"]["reactable_id"]).to eq(article.id)
      end
    end
  end

  context "when a reaction is destroyed" do
    let(:destroyed_reaction) { article_reaction.destroy }
    let(:notification) { create(:notification, user: user, notifiable: article, action: "Reaction", subforem_id: subforem.id) }

    it "doesn't change notifications count" do
      expect do
        described_class.call(reaction_data(destroyed_reaction), user)
      end.not_to change(Notification, :count)
    end

    it "destroys the notification if it exists" do
      notification
      expect do
        described_class.call(reaction_data(destroyed_reaction), user)
      end.to change(Notification, :count).by(-1)
    end

    it "destroys the correct notification if it exists" do
      notification
      described_class.call(reaction_data(destroyed_reaction), user)
      expect(Notification.where(id: notification.id)).not_to be_any
    end

    it "returns deleted action" do
      notification
      result = described_class.call(reaction_data(destroyed_reaction), user)
      expect(result.action).to eq(:deleted)
    end
  end

  context "when a reaction is destroyed but it has siblings" do
    let(:destroyed_reaction) { article_reaction.destroy }
    let!(:notification) { create(:notification, user: user, notifiable: article, action: "Reaction") }

    before do
      create(:reaction, reactable: article, user: user3)
    end

    it "does not destroy or create notifications" do
      expect do
        described_class.call(reaction_data(destroyed_reaction), user)
      end.not_to change(Notification, :count)
    end

    it "keeps the notification" do
      described_class.call(reaction_data(destroyed_reaction), user)
      notification.reload
      expect(notification.notified_at).not_to be_nil
      expect(notification.json_data["user"]["id"]).to eq(user3.id)
      expect(notification.json_data["user"]["username"]).to eq(user3.username)
      expect(notification.json_data["reaction"]["aggregated_siblings"].map { |s| s["user"]["id"] }).to eq([user3.id])
    end

    it "returns saved action" do
      result = described_class.call(reaction_data(destroyed_reaction), user)
      expect(result.action).to eq(:saved)
      expect(result.notification_id).to eq(notification.id)
    end
  end

  # regression test for #16627 and #16570
  context "when a found reaction has unexpected json data" do
    let(:existing_notification) do
      create(
        :notification,
        json_data: { user: {}, article: {} },
        action: "Reaction",
        user: user,
      )
    end

    it "does not raise error" do
      reaction = create(:reaction, reactable: existing_notification.notifiable)
      expect { described_class.call(reaction_data(reaction), user) }.not_to raise_error
    end
  end

  context "when a receiver is an organization" do
    let(:organization) { create(:organization) }

    it "creates a notification" do
      expect do
        described_class.call(reaction_data(article_reaction), organization)
      end.to change(Notification, :count).by(1)
    end

    it "creates a correct notification" do
      result = described_class.call(reaction_data(article_reaction), organization)
      notification = Notification.find(result.notification_id)
      expect(notification.organization_id).to eq(organization.id)
      expect(notification.user_id).to be_nil
      expect(notification.notifiable).to eq(article)
    end
  end
end
