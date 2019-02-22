require "rails_helper"

RSpec.describe "Editing A Comment", type: :system, js: true do
  let!(:user) { create(:user) }
  let!(:article) { create(:article, show_comments: true) }
  let(:new_comment_text) { Faker::Lorem.paragraph }
  let!(:comment) { create(:comment, commentable: article, user: user) }

  before do
    sign_in user
  end

  context "when user edits comment on the bottom of the article" do
    it "updates" do
      visit article.path
      click_link("EDIT")
      expect(page).to have_css("textarea[autofocus='autofocus']")
      fill_in "text-area", with: new_comment_text
      click_button("SUBMIT")
      expect(page).to have_text(new_comment_text)
    end
  end

  context "when user edits via permalinks" do
    it "updates" do
      visit user.comments.last.path
      click_link("EDIT")
      expect(page).to have_css("textarea[autofocus='autofocus']")
      fill_in "text-area", with: new_comment_text
      click_button("SUBMIT")
      expect(page).to have_text(new_comment_text)
    end
  end
end
