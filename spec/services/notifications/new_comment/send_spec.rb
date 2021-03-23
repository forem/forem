require "rails_helper"

RSpec.describe Notifications::NewComment::Send, type: :service do
  let(:user)                 { create(:user) }
  let(:user2)                { create(:user) }
  let(:user3)                { create(:user) }
  let(:top_level_subscriber) { create(:user) }
  let(:organization)         { create(:organization) }
  let(:article)              { create(:article, :with_notification_subscription, user_id: user.id) }
  let(:comment)              { create(:comment, commentable: article, user: user2) }
  let(:author_comment)       { create(:comment, commentable: article, user: user) }
  let!(:child_comment)       { create(:comment, commentable: article, parent: comment, user: user3) }

  it "creates users notifications" do
    expect do
      described_class.call(child_comment)
    end.to change(Notification, :count).by(2)
  end

  it "creates a correct user notification" do
    described_class.call(child_comment)

    notification = child_comment.notifications.last

    expect(notification.action).to be_nil
    expect(notification.json_data["user"]["id"]).to eq(child_comment.user.id)
    expect(notification.json_data["user"]["username"]).to eq(child_comment.user.username)
  end

  it "does not send if comment has negative score already" do
    prior_notification_size = Notification.all.size
    child_comment.update_column(:score, -1)
    described_class.call(child_comment)
    expect(Notification.all.size).to eq prior_notification_size
  end

  it "creates the correct comment data for the notification" do
    described_class.call(child_comment)

    notification = child_comment.notifications.last
    json_data = notification.json_data

    expect(json_data["comment"]["id"]).to eq(child_comment.id)
    expect(Time.zone.parse(json_data["comment"]["created_at"]).to_i).to eq(child_comment.created_at.to_i)
    expect(Time.zone.parse(json_data["comment"]["updated_at"]).to_i).to eq(child_comment.updated_at.to_i)
    expect(json_data["comment"]["ancestors"]).to be_present
    expect(json_data["comment"]["commentable"]).to be_present
    expect(json_data["comment"]["processed_html"]).to be_present
  end

  it "creates notifications for the article author and the parent comment author" do
    described_class.call(child_comment)
    child_comment.reload
    notified_user_ids = Notification.where(notifiable_type: "Comment", notifiable_id: child_comment.id).pluck(:user_id)
    expect(notified_user_ids.sort).to eq([user.id, user2.id].sort)
  end

  it "creates notifications for all subscribed users" do
    create(:notification_subscription, user: user3, notifiable: article)
    create(:notification_subscription, user: top_level_subscriber, notifiable: article, config: "top_level_comments")
    described_class.call(comment)
    notified_user_ids = Notification.where(notifiable_type: "Comment", notifiable_id: comment.id).pluck(:user_id)
    expect(notified_user_ids.sort).to eq([user.id, user3.id, top_level_subscriber.id].sort)
  end

  it "creates author comments notification" do
    create(:notification_subscription, user: user3, notifiable: article, config: "only_author_comments")
    described_class.call(author_comment)
    notified_user_ids = Notification.where(notifiable_type: "Comment",
                                           notifiable_id: author_comment.reload.id).pluck(:user_id)
    expect(notified_user_ids.sort).to eq([user3.id].sort)
  end

  it "doesn't create a notification for top-level-only subscribed users" do
    create(:notification_subscription, user: top_level_subscriber, notifiable: article, config: "top_level_comments")
    described_class.call(child_comment)
    notified_user_ids = Notification.where(notifiable_type: "Comment", notifiable_id: child_comment.id).pluck(:user_id)
    expect(notified_user_ids.sort).to eq([user.id, user2.id].sort)
  end

  it "doesn't create a notification for the author of the article if they are not subscribed" do
    article.notification_subscriptions.delete_all
    described_class.call(comment)
    expect(Notification.count).to eq 0
  end

  it "doesn't create a notification if the receive notification is false" do
    comment.update_column(:receive_notifications, false)
    described_class.call(child_comment)
    notified_user_ids = Notification.where(notifiable_type: "Comment", notifiable_id: child_comment.id).pluck(:user_id)
    expect(notified_user_ids).to eq([user.id].sort)
  end

  it "creates an organization notification" do
    article.update_column(:organization_id, organization.id)
    described_class.call(child_comment)
    expect(Notification.where(notifiable_type: "Comment", notifiable_id: child_comment.id,
                              organization_id: organization.id)).to be_any
  end

  it "sends Push Notifications using Pusher Beams when configured" do
    allow(ApplicationConfig).to receive(:[]).with("PUSHER_BEAMS_KEY").and_return("x" * 64)
    allow(ApplicationConfig).to receive(:[]).with("APP_PROTOCOL").and_return("http://")
    allow(ApplicationConfig).to receive(:[]).with("APP_DOMAIN").and_return("localhost:3000")

    allow(Pusher::PushNotifications).to receive(:publish_to_interests)

    comment_sent = child_comment
    described_class.call(comment_sent)

    channels = ["user-notifications-#{user2.id}", "user-notifications-#{user.id}"]
    payload = described_class.new(comment_sent).__send__(:push_notification_payload)
    expect(Pusher::PushNotifications).to have_received(:publish_to_interests) do |block|
      expect(block[:interests]).to match_array(channels)
      expect(block[:payload]).to eq(payload)
    end
  end
end
