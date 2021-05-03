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

    it "shows user's comments", js: true do
      within("#substories div.profile-comment-card") do
        expect(page).to have_content("All 2 comments")
        expect(page).to have_link(nil, href: comment.path)
        expect(page).to have_link(nil, href: comment2.path)
      end
    end
  end

  context "when user has too many comments" do
    it "show user's last comments ", js: true do
      stub_const("CommentsHelper::MAX_COMMENTS_TO_RENDER", 1)
      visit "/user3000/comments"
      within("#substories div.profile-comment-card") do
        expect(page).to have_content("Last 1 comments")
      end
    end
  end
end
