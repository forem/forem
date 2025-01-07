require "rails_helper"

RSpec.shared_examples "mentionable" do
  let(:mention) { create(:mention, mentionable: mentionable, user: user) }

  it "creates a mention notification" do
    expect do
      described_class.call(mention)
    end.to change(Notification, :count).by(1)
  end

  it "creates a correct mention notification", :aggregate_failures do
    notification = described_class.call(mention)
    mentionable_type = mentionable.class.to_s.downcase
    expect(notification.user_id).to eq(user.id)
    expect(notification.notifiable).to eq(mention)
    expect(notification.json_data[mentionable_type]["path"]).to eq(mentionable.path)
  end

  it "sends from proper mentioner" do
    notification = described_class.call(mention)
    expect(notification.json_data["user"]["id"]).to eq(mentionable.user_id)
  end
end

RSpec.describe Notifications::NewMention::Send, type: :service do
  let(:user) { create(:user) }
  let(:subforem) { create(:subforem) }
  let!(:article) { create(:article, subforem: subforem) }
  let(:article_author) { article.user }
  let!(:mention) { create(:mention, mentionable: article, user: user) }

  it "creates users notifications" do
    expect do
      described_class.call(mention)
    end.to change(Notification, :count).by(1)
  end

  it "creates a correct user notification" do
    described_class.call(mention)

    notification = Notification.last

    expect(notification.notifiable_type).to eq("Mention")
    expect(notification.notifiable_id).to eq(mention.id)
    expect(notification.user_id).to eq(mention.user.id)
    expect(notification.action).to be_nil
    expect(notification.subforem_id).to eq(article.subforem_id)
    expect(notification.json_data["user"]["id"]).to eq(article.user.id)
    expect(notification.json_data["user"]["username"]).to eq(article.user.username)
  end

  it "creates a mobile notification with name of the mentionable author" do
    user.notification_setting.update(mobile_mention_notifications: true)
    allow(PushNotifications::Send).to receive(:call)
    allow(I18n).to receive(:t).with("services.notifications.new_mention.new")
    allow(I18n).to receive(:l)
    allow(I18n).to receive(:t).with("views.notifications.mention.article_mobile",
                                    user: mention.mentionable.user.username,
                                    title: anything).and_call_original

    described_class.call(mention)
    expect(PushNotifications::Send).to have_received(:call)
    expect(I18n).to have_received(:t).twice
  end

  it "does not send if the article has negative score already" do
    prior_notification_size = Notification.all.size
    article.update_column(:score, -1)
    described_class.call(mention)
    expect(Notification.all.size).to eq prior_notification_size
  end

  it "doesn't create a mobile notification if the mobile receive notification is false" do
    user.notification_setting.update(mobile_mention_notifications: false)
    allow(PushNotifications::Send).to receive(:call)

    described_class.call(mention)
    expect(PushNotifications::Send).not_to have_received(:call)
  end
end
