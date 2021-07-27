require "rails_helper"

RSpec.describe "DiscussionLocks", type: :request do
  let(:user) { create(:user) }
  let(:cache_buster) { EdgeCache::BustArticle }

  before { sign_in user }

  describe "POST /discussion_locks - DiscussionLocks#create" do
    it "creates a DiscussionLock" do
      article = create(:article, user: user)
      reason = "Unproductice comments."
      notes = "Hostile comment from user @user"
      valid_attributes = { article_id: article.id, locking_user_id: user.id, notes: notes, reason: reason }
      expect do
        post discussion_locks_path, params: { discussion_lock: valid_attributes }
      end.to change(DiscussionLock, :count).by(1)

      expect(request.flash[:success]).to include("Discussion was successfully locked!")
      discussion_lock = DiscussionLock.last
      expect(discussion_lock.article_id).to eq article.id
      expect(discussion_lock.locking_user_id).to eq user.id
      expect(discussion_lock.notes).to eq notes
      expect(discussion_lock.reason).to eq reason
    end

    it "returns an error for an Article that already has a DiscussionLock" do
      article = create(:article, :with_discussion_lock, user: user)
      invalid_article_attributes = { article_id: article.id, locking_user_id: user.id }
      expect do
        post discussion_locks_path, params: { discussion_lock: invalid_article_attributes }
      end.to change(DiscussionLock, :count).by(0)

      expect(request.flash[:error]).to include("Error: Article has already been taken")
    end

    it "busts the cache for the article" do
      article = create(:article, user: user)
      allow(cache_buster).to receive(:call).with(article)
      valid_attributes = { article_id: article.id, locking_user_id: user.id }

      post discussion_locks_path, params: { discussion_lock: valid_attributes }

      expect(cache_buster).to have_received(:call).with(article).once
    end

    it "does not allow to lock another user's article" do
      article = create(:article, user: user)
      other_user = create(:user)
      sign_out user
      sign_in other_user

      reason = "Unproductice comments."
      notes = "Hostile comment from user @user"
      valid_attributes = { article_id: article.id, locking_user_id: other_user.id, notes: notes, reason: reason }
      expect do
        post discussion_locks_path, params: { discussion_lock: valid_attributes }
      end.to raise_error(Pundit::NotAuthorizedError)
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
      allow(cache_buster).to receive(:call).with(article)
      discussion_lock = create(:discussion_lock, article_id: article.id, locking_user_id: user.id)

      delete discussion_lock_path(discussion_lock.id)

      expect(cache_buster).to have_received(:call).with(article).once
    end
  end
end
