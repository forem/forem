require "rails_helper"

RSpec.describe Notifications::NewMention::Send, type: :service do
  let(:user) { create(:user) }
  let(:comment) { create(:comment, commentable: create(:article)) }
  let(:mention) { create(:mention, mentionable: comment, user: user) }
  # let(:user2)           { create(:user) }
  # let(:user3)           { create(:user) }
  # let(:organization)    { create(:organization) }
  # let(:article)         { create(:article, user_id: user.id, page_views_count: 4000, positive_reactions_count: 70) }
  # let!(:follow)         { user.follow(user2) }

  it "creates a mention notification" do
    expect do
      described_class.call(mention)
    end.to change(Notification, :count).by(1)
  end

  it "creates a correct mention notification" do
    notification = described_class.call(mention)
    expect(notification.user_id).to eq(user.id)
    expect(notification.notifiable).to eq(mention)
    expect(notification.json_data["comment"]["path"]).to eq(comment.path)
  end
end
