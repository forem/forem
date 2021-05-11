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
  let!(:article) { create(:article) }

  it_behaves_like "mentionable" do
    let(:mentionable) { create(:comment, commentable: article) }
  end

  it_behaves_like "mentionable" do
    let(:mentionable) { article }
  end
end
