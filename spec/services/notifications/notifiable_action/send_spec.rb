require "rails_helper"

RSpec.describe Notifications::NotifiableAction::Send, type: :service do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:subforem) { create(:subforem) }
  let(:article) { create(:article, user: user, organization: organization, subforem: subforem) }

  let(:user2) { create(:user) }
  let(:user3) { create(:user) }

  context "when following a user or organization" do
    before do
      user2.follow(user)
      user3.follow(organization)
    end

    it "creates notifications" do
      expect do
        described_class.call(article, "Published")
      end.to change(Notification, :count).by(2)
    end

    it "creates a correct user notification", :aggregate_failures do
      described_class.call(article, "Published")
      notifications = Notification.where(user_id: user2.id, notifiable_id: article.id, notifiable_type: "Article")
      expect(notifications.size).to eq(1)
      notification = notifications.first
      expect(notification.subforem_id).to eq(subforem.id)
      expect(notification.action).to eq("Published")
      expect(notification.json_data["article"]["id"]).to eq(article.id)
      expect(notification.json_data["user"]["id"]).to eq(user.id)
      expect(notification.json_data["user"]["username"]).to eq(user.username)
    end

    it "creates a correct organization notification", :aggregate_failures do
      described_class.call(article, "Published")
      notifications = Notification.where(user_id: user3.id, notifiable_id: article.id, notifiable_type: "Article")
      expect(notifications.size).to eq(1)
      notification = notifications.first
      expect(notification.action).to eq("Published")
      expect(notification.json_data["article"]["id"]).to eq(article.id)
      expect(notification.json_data["user"]["id"]).to eq(user.id)
      expect(notification.json_data["organization"]["id"]).to eq(organization.id)
      expect(notification.json_data["organization"]["name"]).to eq(organization.name)
    end

    it "creates a context notification" do
      expect do
        described_class.call(article, "Published")
      end.to change(ContextNotification, :count).by(1)
    end

    it "creates a correct context notification" do
      described_class.call(article, "Published")
      context_notifications = article.context_notifications
      expect(context_notifications.pluck(:action)).to eq(["Published"])
    end

    it "does not create a notification if the follower has muted the user" do
      user2.follows.first.update(subscription_status: "none")
      user3.stop_following(organization)
      described_class.call(article, "Published")
      expect(Notification.count).to eq(0)
      expect(ContextNotification.count).to eq(0)
    end

    it "doesn't fail if the notification already exists" do
      create(:notification, user: user2, action: "Published", notifiable: article)
      expect do
        described_class.call(article, "Published")
      end.not_to raise_error
    end

    it "upserts the existing notification" do
      time = Date.yesterday
      notification = create(:notification, user: user2, action: "Published", notifiable: article)
      notification.update_columns(updated_at: time, created_at: time)
      described_class.call(article, "Published")
      notification.reload
      expect(notification.created_at).to be > time
    end

    it "doesn't fail if the context notification already exists" do
      create(:context_notification, action: "Published", context: article)
      expect do
        described_class.call(article, "Published")
      end.not_to raise_error
    end
  end

  context "when following a user or organization and being mentioned in an article" do
    it "does not create a notification when following a user" do
      user2.follow(user)
      create(:mention, mentionable: article, user: user2)

      described_class.call(article, "Published")
      expect(Notification.count).to eq(0)
      expect(ContextNotification.count).to eq(0)
    end

    it "does not create a notification when following an organization" do
      user3.follow(organization)
      create(:mention, mentionable: article, user: user3)

      described_class.call(article, "Published")
      expect(Notification.count).to eq(0)
      expect(ContextNotification.count).to eq(0)
    end
  end

  context "when publishing an article under an organization" do
    it "doesn't create a notification for the article author" do
      user = create(:user)
      organization = create(:organization)
      user.follow(organization)
      article = create(:article, user: user, organization: organization)

      expect do
        described_class.call(article, "Published")
      end.not_to change(Notification, :count)
    end
  end
end
