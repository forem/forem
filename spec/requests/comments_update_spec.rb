require "rails_helper"

RSpec.describe "CommentsUpdate" do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:comment) { create(:comment, user_id: user.id, commentable: article) }

  before do
    sign_in user
    Notification.send_new_comment_notifications_without_delay(comment)
  end

  it "updates ordinary article with proper params" do
    new_body = "NEW TITLE #{rand(100)}"
    put "/comments/#{comment.id}", params: {
      comment: { body_markdown: new_body }
    }
    expect(Comment.last.processed_html).to include(new_body)
  end

  it "doesn't redirect" do
    new_body = "NEW TITLE #{rand(100)}"
    put "/comments/#{comment.id}", params: {
      comment: { body_markdown: new_body }
    }
    expect(response).not_to have_http_status(:redirect)
    expect(response).to have_http_status(:ok)
  end
end
