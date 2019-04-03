require "rails_helper"

RSpec.describe Notifications::NewComment::Send, type: :service do
  let(:user)            { create(:user) }
  let(:user2)           { create(:user) }
  let(:user3)           { create(:user) }
  let(:organization)    { create(:organization) }
  let(:article)         { create(:article, user_id: user.id) }
  let(:comment)         { create(:comment, commentable: article, user: user2) }
  let!(:child_comment) { create(:comment, commentable: article, parent: comment, user: user3) }

  it "creates users notifications" do
    expect do
      described_class.call(child_comment)
    end.to change(Notification, :count).by(2)
  end

  it "creates notifications for the article author and the parent comment author" do
    described_class.call(child_comment)
    child_comment.reload
    notified_user_ids = Notification.where(notifiable_type: "Comment", notifiable_id: child_comment.id).map(&:user_id)
    expect(notified_user_ids.sort).to eq([user.id, user2.id].sort)
  end

  it "doesn't create notification if the receive notification is false" do
    comment.update_column(:receive_notifications, false)
    described_class.call(child_comment)
    notified_user_ids = Notification.where(notifiable_type: "Comment", notifiable_id: child_comment.id).map(&:user_id)
    expect(notified_user_ids).to eq([user.id].sort)
  end

  it "creates an organization notification" do
    article.update_column(:organization_id, organization.id)
    described_class.call(child_comment)
    expect(Notification.where(notifiable_type: "Comment", notifiable_id: child_comment.id, organization_id: organization.id)).to be_any
  end
end
