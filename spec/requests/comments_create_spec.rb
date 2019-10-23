require "rails_helper"

RSpec.describe "CommentsCreate", type: :request do
  let(:user) { create(:user) }
  let(:blocker) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }

  before do
    sign_in user
  end

  it "creates ordinary article with proper params" do
    new_body = "NEW BODY #{rand(100)}"
    post "/comments", params: {
      comment: { body_markdown: new_body, commentable_id: article.id, commentable_type: "Article" }
    }
    expect(Comment.last.user_id).to eq(user.id)
  end

  it "creates NotificationSubscription for comment" do
    new_body = "NEW BODY #{rand(100)}"
    post "/comments", params: {
      comment: { body_markdown: new_body, commentable_id: article.id, commentable_type: "Article" }
    }
    expect(NotificationSubscription.last.notifiable).to eq(Comment.last)
  end

  context "when user is posting on an author that blocks user" do
    it "returns unauthorized" do
      create(:user_block, blocker: blocker, blocked: user, config: "default")
      user.update(blocked_by_count: 1)
      blocker_article = create(:article, user_id: blocker.id)
      expect do
        post "/comments", params: {
          comment: { body_markdown: "something", commentable_id: blocker_article.id, commentable_type: "Article" }
        }
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when user is posting on an author that does not block user, but the user has been blocked elsewhere" do
    it "returns unauthorized" do
      user.update(blocked_by_count: 1)
      blocker_article = create(:article, user_id: blocker.id)
      post "/comments", params: {
        comment: { body_markdown: "something allowed", commentable_id: blocker_article.id, commentable_type: "Article" }
      }
      new_comment = Comment.last
      expect(new_comment.body_markdown).to eq("something allowed")
      expect(new_comment.id).not_to eq(nil)
    end
  end
end
