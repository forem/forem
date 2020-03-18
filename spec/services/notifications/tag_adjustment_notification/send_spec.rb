require "rails_helper"

RSpec.describe Notifications::TagAdjustmentNotification::Send, type: :service do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:article) { create(:article, title: "My title", user: user2, body_markdown: "---\ntitle: Hellohnnnn#{rand(1000)}\npublished: true\ntags: heyheyhey,#{tag.name}\n---\n\nHello") }
  let(:tag) { create(:tag) }
  let(:mod_user) { create(:user) }
  let(:tag_adjustment) { create(:tag_adjustment, user_id: mod_user.id, article_id: article.id, tag_id: tag.id, adjustment_type: "addition") }
  let(:notification) { described_class.call(tag_adjustment) }

  before do
    mod_user.add_role(:tag_moderator, tag)
  end

  it "returns a valid notification" do
    expect(notification).to be_a(Notification)
  end

  it "notifies the author of the article" do
    sidekiq_perform_enqueued_jobs do
      Notification.send_tag_adjustment_notification(tag_adjustment)
    end
    expect(Notification.first.user_id).to eq user2.id
  end

  specify "notification to have valid attributes", :aggregate_failures do
    expect(notification.user_id).to eq(article.user_id)
    expect(notification.notifiable_id).to eq(tag_adjustment.id)
    expect(notification.notifiable_type).to eq(tag_adjustment.class.name)
  end

  it "tests JSON data" do
    json = notification.json_data
    expect(json["article"]["title"]).to start_with("Hello")
    expect(json["adjustment_type"]). to eq "addition"
  end

  it "tests JSON data for removal" do
    tag_adjustment.adjustment_type = "removal"
    json = notification.json_data
    expect(json["article"]["title"]).to start_with("Hello")
    expect(json["adjustment_type"]). to eq "removal"
  end

  specify "notification to be inserted on DB" do
    expect do
      described_class.call(tag_adjustment)
    end.to change(Notification, :count).by(1)
  end
end
