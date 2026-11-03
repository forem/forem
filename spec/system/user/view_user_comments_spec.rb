require "rails_helper"

RSpec.describe "User comments" do
  let!(:user) { create(:user, username: "user3000", profile_image: nil) }
  let!(:article) { create(:article, user: user, with_tags: false) }
  let!(:other_article) { create(:article, with_tags: false) }
  let!(:comment) { create(:comment, user: user, commentable: other_article) }
  let!(:comment2) { create(:comment, user: user, commentable: other_article) }

  context "when user is authorized" do
    before do
      sign_in user
      visit "/user3000/comments"
    end

    it "shows user's comments without articles or the locked cta", :aggregate_failures do
      within("#substories") do
        expect(page).to have_no_content(article.title)
        expect(page).to have_no_content("Want to connect with #{user.name}?")
      end

      within("#substories div.profile-comment-card") do
        expect(page).to have_content("All comments")
        expect(page).to have_link(nil, href: comment.path)
        expect(page).to have_link(nil, href: comment2.path)
      end
    end
  end

  context "when user is unauthorized" do
    before { visit "/user3000/comments" }

    it "shows comments locked cta while hiding user's articles and comments", :aggregate_failures do
      within("#substories") do
        expect(page).to have_no_content(article.title)
        expect(page).to have_no_content("All comments")
        expect(page).to have_no_link(nil, href: comment.path)
        expect(page).to have_no_link(nil, href: comment2.path)
        expect(page).to have_content("Want to connect with #{user.name}?")
      end
    end
  end

  context "when user has too many comments" do
    before do
      stub_const("CommentsHelper::MAX_COMMENTS_TO_RENDER", 1)
      sign_in user
      visit "/user3000/comments"
    end

    it "show user's last comments" do
      within("#substories div.profile-comment-card") do
        expect(page).to have_content("Recent comments")
      end
    end
  end
end
