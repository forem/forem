require "rails_helper"

RSpec.describe "User comments", type: :system do
  let!(:user) { create(:user, username: "user3000") }
  let!(:article) { create(:article, user: user) }
  let!(:comment) { create(:comment, user: user, commentable: create(:article)) }
  let!(:comment2) { create(:comment, user: user, commentable: create(:article)) }

  context "when user is unauthorized" do
    before { visit "/user3000/comments" }

    it "does not show user's articles" do
      within("#substories") do
        expect(page).not_to have_content(article.title)
      end
    end

    it "shows user's comments" do
      within("#substories div.index-comments") do
        expect(page).to have_content("All 2 Comments")
        expect(page).to have_link(nil, href: comment.path)
        expect(page).to have_link(nil, href: comment2.path)
      end
    end
  end
end
