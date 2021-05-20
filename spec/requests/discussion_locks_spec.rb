require "rails_helper"

RSpec.describe "DiscussionLocks", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "POST /discussion_locks - DiscussionLocks#create" do
    it "creates a DiscussionLock" do
      article = create(:article, user: user)
      reason = "Unproductice comments."
      valid_attributes = { article_id: article.id, locking_user_id: user.id, reason: reason }
      expect do
        post discussion_locks_path,
             headers: { "Content-Type" => "application/json" },
             params: { discussion_lock: valid_attributes }.to_json
      end.to change(DiscussionLock, :count).by(1)

      discussion_lock = DiscussionLock.last
      expect(discussion_lock.article_id).to eq article.id
      expect(discussion_lock.locking_user_id).to eq user.id
      expect(discussion_lock.reason).to eq reason
    end

    it "returns an error for an invalid Article" do
      invalid_article_attributes = { article_id: "nonexistant-id", locking_user_id: user.id }
      expect do
        post discussion_locks_path,
             headers: { "Content-Type" => "application/json" },
             params: { discussion_lock: invalid_article_attributes }.to_json
      end.to change(DiscussionLock, :count).by(0)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("Article must exist")
    end

    it "busts the cache for the article" do
      article = create(:article, user: user)
      valid_attributes = { article_id: article.id, locking_user_id: user.id }

      sidekiq_assert_enqueued_jobs(1, only: Articles::BustCacheWorker) do
        post discussion_locks_path,
             headers: { "Content-Type" => "application/json" },
             params: { discussion_lock: valid_attributes }.to_json
      end
    end
  end

  describe "DELETE /discussion_locks/:id - DiscussionLocks#destroy" do
    it "destroys a DiscussionLock" do
      article = create(:article, user: user)
      discussion_lock = create(:discussion_lock, article_id: article.id, locking_user_id: user.id)
      expect do
        delete discussion_lock_path(discussion_lock.id)
      end.to change(DiscussionLock, :count).by(-1)
    end

    it "busts the cache for the article" do
      article = create(:article, user: user)
      discussion_lock = create(:discussion_lock, article_id: article.id, locking_user_id: user.id)

      sidekiq_assert_enqueued_jobs(1, only: Articles::BustCacheWorker) do
        delete discussion_lock_path(discussion_lock.id)
      end
    end
  end
end
