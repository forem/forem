require "rails_helper"

RSpec.describe Notifications::RemoveEach do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:comment) { create(:comment, user_id: user.id, commentable_id: article.id) }
  let(:comment2) { create(:comment, user_id: user2.id, commentable_id: article.id) }
  let(:mention) { create(:mention, user_id: user.id, mentionable_id: comment.id, mentionable_type: "Comment") }
  let(:mention2) { create(:mention, user_id: user2.id, mentionable_id: comment2.id, mentionable_type: "Comment") }
  let(:notifiable_collection_ids) { [mention.id, mention2.id] }

  before do
    create(:notification, user_id: mention.user.id, notifiable_id: mention.id, notifiable_type: "Mention")
    create(:notification, user_id: mention2.user.id, notifiable_id: mention2.id, notifiable_type: "Mention")
  end

  it "checks all notifiables are deleted" do
    expect { described_class.call(notifiable_collection_ids) }.to change(Notification, :count).by(-2)
  end
end
