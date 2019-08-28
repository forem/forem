require "rails_helper"

RSpec.describe Notifications::NotifiableAction::Send, type: :service do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:article) { create(:article, user: user, organization: organization) }

  let(:user2) { create(:user) }
  let(:user3) { create(:user) }

  before do
    user2.follow(user)
    user3.follow(organization)
  end

  it "creates notifications" do
    expect do
      described_class.call(article, "Published")
    end.to change(Notification, :count).by(2)
  end

  it "creates a correct user notification" do
    described_class.call(article, "Published")
    notifications = Notification.where(user_id: user2.id, notifiable_id: article.id, notifiable_type: "Article")
    expect(notifications.size).to eq(1)
    notification = notifications.first
    expect(notification.action).to eq("Published")
    expect(notification.json_data["article"]["id"]).to eq(article.id)
    expect(notification.json_data["user"]["id"]).to eq(user.id)
    expect(notification.json_data["user"]["username"]).to eq(user.username)
  end

  it "creates a correct organization notification" do
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

  it "does not create a notification if the follower has muted the user" do
    user2.follows.first.update(subscription_status: "none")
    user3.stop_following(organization)
    described_class.call(article, "Published")
    expect(Notification.count).to eq 0
  end
end
