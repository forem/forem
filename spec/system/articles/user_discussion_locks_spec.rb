require "rails_helper"

RSpec.describe "User discussion locks", type: :system, js: true do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }
  let(:discussion_lock) { create(:discussion_lock, article: article, locking_user: user) }

  before do
    article
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
  end
end
