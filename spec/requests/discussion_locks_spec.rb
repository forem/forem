require "rails_helper"

RSpec.describe "DiscussionLocks" do
  let(:user) { create(:user) }
  let(:cache_buster) { EdgeCache::BustArticle }

  before { sign_in user }

  describe "POST /discussion_locks - DiscussionLocks#create" do
    it "creates a DiscussionLock" do
      article = create(:article, user: user)
      reason = "Unproductive comments."
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
      end.not_to change(DiscussionLock, :count)

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

      reason = "Unproductive comments."
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

  describe "discussion lock UI state on manage, article, and comment pages" do
    let(:article) { create(:article, user: user) }
    let!(:comment_one) { create(:comment, user: user, commentable: article) }
    let!(:comment_two) { create(:comment, user: user, commentable: article) }

    context "when an Article does not have a discussion lock" do
      it "shows Lock Discussion on manage and enables new comment form and reply buttons", :aggregate_failures do
        get "#{article.path}/manage"
        manage_doc = Nokogiri::HTML(response.body)
        expect(manage_doc.at_css("#section-discussion a[href='#{article.path}/discussion_lock_confirm']")&.text)
          .to include("Lock Discussion")

        get article.path
        article_doc = Nokogiri::HTML(response.body)
        expect(article_doc.at_css("#discussion-lock")).to be_nil
        expect(article_doc.at_css("#new_comment")).to be_present
        expect(article_doc.at_css("[data-testid='reply-button-#{comment_one.id}']")).to be_present
        expect(article_doc.at_css("[data-testid='reply-button-#{comment_two.id}']")).to be_present

        get "#{article.path}/comments"
        comments_doc = Nokogiri::HTML(response.body)
        expect(comments_doc.at_css("#new_comment")).to be_present
        expect(comments_doc.at_css("[data-testid='reply-button-#{comment_one.id}']")).to be_present
        expect(comments_doc.at_css("[data-testid='reply-button-#{comment_two.id}']")).to be_present

        get "#{article.path}/comments/#{comment_one.id.to_s(26)}"
        expect(Nokogiri::HTML(response.body).at_css("[data-testid='reply-button-#{comment_one.id}']")).to be_present

        get comment_one.path
        expect(Nokogiri::HTML(response.body).at_css("[data-testid='reply-button-#{comment_one.id}']")).to be_present
      end
    end

    context "when an Article has a discussion lock" do
      let!(:discussion_lock) { create(:discussion_lock, article: article, locking_user: user) }

      it "shows Unlock Discussion on manage and hides new comment form and reply buttons", :aggregate_failures do
        get "#{article.path}/manage"
        manage_doc = Nokogiri::HTML(response.body)
        expect(manage_doc.at_css("#section-discussion a[href='#{article.path}/discussion_unlock_confirm']")&.text)
          .to include("Unlock Discussion")

        get article.path
        article_doc = Nokogiri::HTML(response.body)
        lock_node = article_doc.at_css("#discussion-lock")
        expect(lock_node).to be_present
        expect(lock_node.text).to include("The discussion has been locked. New comments can't be added.")
        expect(lock_node.text).to include(discussion_lock.reason)
        expect(article_doc.at_css("#new_comment")).to be_nil
        expect(article_doc.at_css("[data-testid='reply-button-#{comment_one.id}']")).to be_nil
        expect(article_doc.at_css("[data-testid='reply-button-#{comment_two.id}']")).to be_nil

        get "#{article.path}/comments"
        comments_doc = Nokogiri::HTML(response.body)
        expect(comments_doc.at_css("#new_comment")).to be_nil
        expect(comments_doc.at_css("[data-testid='reply-button-#{comment_one.id}']")).to be_nil
        expect(comments_doc.at_css("[data-testid='reply-button-#{comment_two.id}']")).to be_nil

        get "#{article.path}/comments/#{comment_one.id.to_s(26)}"
        expect(Nokogiri::HTML(response.body).at_css("[data-testid='reply-button-#{comment_one.id}']")).to be_nil

        get comment_one.path
        expect(Nokogiri::HTML(response.body).at_css("[data-testid='reply-button-#{comment_one.id}']")).to be_nil
      end
    end
  end
end
