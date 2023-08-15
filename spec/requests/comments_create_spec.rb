require "rails_helper"

RSpec.describe "CommentsCreate" do
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

      post comments_path, params: comment_params(commentable_id: blocker_article.id)
      expect(response).to have_http_status(:unprocessable_entity)
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
      expect(new_comment.id).not_to be_nil
    end
  end

  context "when user is commenting on a comment by an author who has blocked the user" do
    before do
      create(:user_block, blocker: blocker, blocked: user, config: "default")
      # Manually manage the blocked_by_count attribute that counter_culture manages in prod
      user.update_column(:blocked_by_count, 1)
    end

    let!(:third_party_article) { create(:article, user_id: create(:user).id) }

    it "raises a ModerationUnauthorizedError to prevent the comment from saving" do
      blocker_comment = create(:comment, user_id: blocker.id, commentable: third_party_article)
      expect do
        post comments_path, params: comment_params(body_markdown: "trolling attempted!",
                                                   parent_id: blocker_comment.id)
      end.not_to change(Comment, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("Not allowed due to moderation action")
    end

    it "raises the error when the commenter is downthread of the blocker" do
      # Simulate a conversation between the blocking user and two other users who aren't blocking anyone
      replier_one = create(:user)
      replier_two = create(:user)
      blocker_comment = create(:comment, user: blocker, body_markdown: "I just block and then keep it moving",
                                         commentable: third_party_article)
      first_reply = create(:comment, user: replier_one, commentable: third_party_article, body_markdown: "+1!",
                                     parent_id: blocker_comment.id)
      downthread_reply = create(:comment, user: replier_two, commentable: third_party_article, body_markdown: "<3",
                                          parent_id: first_reply.id)
      expect do
        post comments_path,
             params: comment_params(body_markdown: "I'd love to derail this convo!", parent_id: downthread_reply.id)
      end.not_to change(Comment, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("Not allowed due to moderation action")
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
