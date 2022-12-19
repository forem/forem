require "rails_helper"

RSpec.describe "User discussion locks", type: :system, js: true do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }
  let(:discussion_lock) { create(:discussion_lock, article: article, locking_user: user) }
  let(:comment_one) { create(:comment, user: user, commentable: article) }
  let(:comment_two) { create(:comment, user: user, commentable: article) }

  before do
    article
    comment_one
    comment_two
    sign_in user
  end

  context "when an Article does not have a discussion lock" do
    it "shows the discussion lock button in manage" do
      visit dashboard_path
      click_on "Manage"

      within "div.dashboard-actions" do
        expect(page).to have_link("Lock discussion", href: "#{article.path}/discussion_lock_confirm")
      end
    end

    it "doesn't show a DiscussionLock on the Article" do
      visit article.path
      expect(page).not_to have_selector("#discussion-lock")
    end

    it "doesn't hide new comment box on the Article" do
      visit article.path
      expect(page).to have_selector("#new_comment")
    end

    it "doesn't hide reply button on each comment on the Article page" do
      visit article.path
      expect(page).to have_selector("[data-testid='reply-button-#{comment_one.id}']")
      expect(page).to have_selector("[data-testid='reply-button-#{comment_two.id}']")
    end

    it "doesn't hide new commment box on the legacy Comments page" do
      visit "#{article.path}/comments"
      expect(page).to have_selector("#new_comment")
    end

    it "doesn't hide reply button on comments on the legacy Comments page" do
      visit "#{article.path}/comments"
      expect(page).to have_selector("[data-testid='reply-button-#{comment_one.id}']")
      expect(page).to have_selector("[data-testid='reply-button-#{comment_two.id}']")
    end

    it "doesn't hide reply button on comments on a legacy Comment page" do
      visit "#{article.path}/comments/#{comment_one.id.to_s(26)}"
      expect(page).to have_selector("[data-testid='reply-button-#{comment_one.id}']")

      visit "#{article.path}/comments/#{comment_two.id.to_s(26)}"
      expect(page).to have_selector("[data-testid='reply-button-#{comment_two.id}']")
    end

    it "doesn't hide reply button on comments on a Comment page" do
      visit comment_one.path
      expect(page).to have_selector("[data-testid='reply-button-#{comment_one.id}']")

      visit comment_two.path
      expect(page).to have_selector("[data-testid='reply-button-#{comment_two.id}']")
    end
  end

  context "when an Article has a discussion lock" do
    before { discussion_lock }

    it "shows the unlock discussion lock button in manage" do
      visit dashboard_path
      click_on "Manage"

      within "div.dashboard-actions" do
        expect(page).to have_link("Unlock discussion", href: "#{article.path}/discussion_unlock_confirm")
      end
    end

    it "shows a DiscussionLock on the Article" do
      visit article.path
      expect(page).to have_selector("#discussion-lock")

      within "#discussion-lock" do
        expect(page).to have_text("The discussion has been locked. New comments can't be added.")
        expect(page).to have_text(discussion_lock.reason)
      end
    end

    it "hides new comment box on the Article" do
      visit article.path
      expect(page).not_to have_selector("#new_comment")
    end

    it "hides reply button on each comment on the Article page" do
      visit article.path
      expect(page).not_to have_selector("[data-testid='reply-button-#{comment_one.id}']")
      expect(page).not_to have_selector("[data-testid='reply-button-#{comment_two.id}']")
    end

    it "hides new comment box on the legacy Comments page" do
      visit "#{article.path}/comments"
      expect(page).not_to have_selector("#new_comment")
    end

    it "hides reply button on comments on the legacy Comments page" do
      visit "#{article.path}/comments"
      expect(page).not_to have_selector("[data-testid='reply-button-#{comment_one.id}']")
      expect(page).not_to have_selector("[data-testid='reply-button-#{comment_two.id}']")
    end

    it "hides reply button on comments on a legacy Comment page" do
      visit "#{article.path}/comments/#{comment_one.id.to_s(26)}"
      expect(page).not_to have_selector("[data-testid='reply-button-#{comment_one.id}']")

      visit "#{article.path}/comments/#{comment_two.id.to_s(26)}"
      expect(page).not_to have_selector("[data-testid='reply-button-#{comment_two.id}']")
    end

    it "hides reply button on comments on a Comment page" do
      visit comment_one.path
      expect(page).not_to have_selector("[data-testid='reply-button-#{comment_one.id}']")

      visit comment_two.path
      expect(page).not_to have_selector("[data-testid='reply-button-#{comment_two.id}']")
    end
  end
end
