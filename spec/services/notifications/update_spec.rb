require "rails_helper"

RSpec.describe Notifications::Update, type: :service do
  let!(:user) { create(:user) }
  let!(:org) { create(:organization) }
  let(:article) { create(:article, organization_id: org.id) }

  context "when article notifications" do
    it "updates" do
      notification = create(:notification, notifiable: article, user: user, action: "Published")
      described_class.call(article, "Published")
      notification.reload
      expect(notification.json_data["user"]["id"]).to eq(article.user.id)
      expect(notification.json_data["user"]["name"]).to eq(article.user.name)
      expect(notification.json_data["organization"]["id"]).to eq(org.id)
      expect(notification.json_data["article"]["id"]).to eq(article.id)
    end

    it "doesn't update another notification" do
      fake_data = { "user" => "hello" }
      notification = create(:notification, notifiable: article, user: user, json_data: fake_data)
      described_class.call(article, "Published")
      notification.reload
      expect(notification.json_data).to eq(fake_data)
    end
  end

  context "when comment notifications" do
    let(:comment) { create(:comment, commentable: article) }

    it "updates comment notifications" do
      notification = create(:notification, notifiable: comment, user: user)
      described_class.call(comment)
      notification.reload
      expect(notification.json_data["comment"]["id"]).to eq(comment.id)
    end
  end
end
