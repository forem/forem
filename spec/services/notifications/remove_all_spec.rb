require "rails_helper"

RSpec.describe Notifications::RemoveAll do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:organization) { create(:organization) }
  let(:article) { create(:article) }
  let(:article2) { create(:article) }
  let(:comment) { create(:comment, user_id: user.id, commentable_id: article.id, commentable_type: "Article") }

  before do
    create(:notification, user: user, notifiable_id: article.id, notifiable_type: "Article", action: "Published")
    create(:notification, user: user2, notifiable_id: article.id, notifiable_type: "Article", action: "Published")
    create(:notification, organization: organization, notifiable_id: comment.id, notifiable_type: "Comment", action: "Reaction")
  end

  it "checks all notifications for an article are deleted and only for an article" do
    expect { described_class.call(article.id, "Article", "Published") }.to change(Notification, :count).by(-2)
  end
end
