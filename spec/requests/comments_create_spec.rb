require "rails_helper"

RSpec.describe "CommentsCreate", type: :request do
  let(:user) { create(:user) }
  let(:blocker) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:new_body) { -> { "NEW BODY #{rand(100)}" } }
  let(:rate_limit_checker) { RateLimitChecker.new(user) }

  before do
    sign_in user
  end

  def comment_params(**kwargs)
    {
      comment: {
        body_markdown: new_body.call,
        commentable_id: article.id,
        commentable_type: "Article"
      }.merge(kwargs)
    }
  end

  it "creates a comment with proper params" do
    expect do
      post comments_path, params: comment_params
    end.to change(user.comments, :count).by(1)
  end

  it "creates NotificationSubscription for comment" do
    post comments_path, params: comment_params

    expect(NotificationSubscription.last.notifiable).to eq(Comment.last)
  end

  context "when users hit their rate limits" do
    before do
      allow(RateLimitChecker).to receive(:new).and_return(rate_limit_checker)
    end

    it "returns 429 Too Many Requests when a user reaches their rate limit" do
      # avoid hitting new user rate limit check
      allow(user).to receive(:created_at).and_return(1.week.ago)
      allow(rate_limit_checker).to receive(:limit_by_action)
        .with(:comment_creation)
        .and_return(true)

      post comments_path, params: comment_params

      expect(response).to have_http_status(:too_many_requests)
    end

    it "returns 429 Too Many Requests when a new user reaches their rate limit" do
      allow(rate_limit_checker).to receive(:limit_by_action)
        .with(:comment_antispam_creation)
        .and_return(true)

      post comments_path, params: comment_params

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  context "when user is posting on an author that blocks user" do
    it "returns unauthorized" do
      create(:user_block, blocker: blocker, blocked: user, config: "default")
      user.update(blocked_by_count: 1)
      blocker_article = create(:article, user: blocker)

      expect do
        post comments_path, params: comment_params(commentable_id: blocker_article.id)
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when user is posting on an author that does not block user, but the user has been blocked elsewhere" do
    it "creates the new comment" do
      user.update(blocked_by_count: 1)
      blocker_article = create(:article, user: blocker)

      post comments_path, params: comment_params(
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
      allow(rate_limit_checker).to receive(:check_limit!).and_raise(StandardError)
    end

    it "returns an unprocessable_entity response code" do
      post comments_path, params: comment_params

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "when a comment is invalid" do
    it "returns the proper JSON response" do
      post comments_path, params: comment_params(body_markdown: "a" * 25_001)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to be_present
    end
  end

  context "when there's already a notification for comment" do
    around do |example|
      Sidekiq::Testing.inline!(&example)
    end

    let(:comment_author) { create(:user) }
    let(:user_replier) { create(:user) }
    let(:moderator_replier) { create(:user, :admin) }
    let(:response_template) do
      create(:response_template, type_of: "mod_comment",
                                 content: text_mentioning_comment_author, user_id: nil)
    end
    let(:text_mentioning_comment_author) do
      "Hello, @#{comment_author.username}"
    end

    it "doesn't create mention notification, when replying as regular user" do
      comment = comment_on_article
      reply_and_mention_comment_author(comment)

      expect_no_duplicate_notifications_for_comment_author
    end

    it "doesn't create mention notification, when replying as moderator" do
      comment = comment_on_article
      reply_and_mention_comment_author_as_moderator(comment)

      expect_no_duplicate_notifications_for_comment_author
    end

    private

    def comment_on_article
      sign_in comment_author
      post comments_path, params: comment_params
      expect_request_to_be_successful

      Comment.first
    end

    def reply_and_mention_comment_author(comment)
      sign_in user_replier
      post comments_path, params: comment_params(
        parent_id: comment.id,
        body_markdown: text_mentioning_comment_author,
      )
      expect_request_to_be_successful
    end

    def reply_and_mention_comment_author_as_moderator(comment)
      allow(Settings::General).to receive(:mascot_user_id)
        .and_return(moderator_replier.id)

      sign_in moderator_replier
      post moderator_create_comments_path, params: comment_params(
        parent_id: comment.id,
      ).merge(response_template: { id: response_template.id })
      expect(response).to be_successful
    end

    def expect_no_duplicate_notifications_for_comment_author
      expect(Mention.count).to eq 0
      expect(Notification.where(user: comment_author).count).to eq 1
    end

    def expect_request_to_be_successful
      expect(response.parsed_body["error"]).to be_nil
      expect(response).to be_successful
    end
  end
end
