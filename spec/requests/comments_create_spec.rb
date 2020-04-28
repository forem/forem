require "rails_helper"

RSpec.describe "CommentsCreate", type: :request do
  let(:user) { create(:user) }
  let(:blocker) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:new_body) { -> { "NEW BODY #{rand(100)}" } }
  let(:rate_limit_checker) { instance_double(RateLimitChecker) }

  before do
    sign_in user
  end

  def comment_params(params = {})
    {
      comment: {
        body_markdown: new_body.call,
        commentable_id: article.id,
        commentable_type: "Article"
      }.merge(params)
    }
  end

  it "creates a comment with proper params" do
    expect do
      post "/comments", params: comment_params
    end.to change(user.comments, :count).by(1)
  end

  it "creates NotificationSubscription for comment" do
    post "/comments", params: comment_params

    expect(NotificationSubscription.last.notifiable).to eq(Comment.last)
  end

  it "returns 429 Too Many Requests when a user reaches their rate limit" do
    allow(RateLimitChecker).to receive(:new).and_return(rate_limit_checker)
    allow(rate_limit_checker).to receive(:limit_by_action).
      with("comment_creation").
      and_return(true)

    post "/comments", params: comment_params

    expect(response).to have_http_status(:too_many_requests)
  end

  context "when user is posting on an author that blocks user" do
    it "returns unauthorized" do
      create(:user_block, blocker: blocker, blocked: user, config: "default")
      user.update(blocked_by_count: 1)
      blocker_article = create(:article, user: blocker)

      expect do
        post "/comments", params: comment_params(commentable_id: blocker_article.id)
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when user is posting on an author that does not block user, but the user has been blocked elsewhere" do
    it "creates the new comment" do
      user.update(blocked_by_count: 1)
      blocker_article = create(:article, user: blocker)

      post "/comments", params: comment_params(
        body_markdown: "something allowed",
        commentable_id: blocker_article.id,
      )

      new_comment = Comment.last
      expect(new_comment.body_markdown).to eq("something allowed")
      expect(new_comment.id).not_to eq(nil)
    end
  end

  context "when an error is raised before authorization is performed" do
    before do
      allow(RateLimitChecker).to receive(:new).and_return(rate_limit_checker)
      allow(rate_limit_checker).to receive(:limit_by_action).and_raise(StandardError)
    end

    it "returns an unprocessable_entity response code" do
      post "/comments", params: comment_params

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "when a comment is invalid" do
    it "returns the proper JSON response" do
      post "/comments", params: comment_params(body_markdown: "a" * 25_001)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to be_present
    end
  end
end
