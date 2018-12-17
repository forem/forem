require "rails_helper"

describe "User index", type: :feature do
  let!(:user) { create(:user, username: "user3000") }
  let!(:article) { create(:article, user: user) }
  let!(:other_article) { create(:article) }
  let!(:comment) { create(:comment, user: user, commentable: other_article) }

  context "when user is unauthorized" do
    before { visit "/user3000" }

    it "shows the header", js: true do
      within("h1") { expect(page).to have_content(user.name) }
      within(".profile-details") do
        expect(page).to have_button("+ FOLLOW")
      end
    end

    it "shows proper title tag" do
      expect(page).to .to have_title("#{user.name} - DEV Community 👩‍💻👨‍💻")
    end

    it "shows user's articles" do
      within(".single-article") do
        expect(page).to have_content(article.title)
        expect(page).not_to have_content(other_article.title)
      end
    end

    it "shows user's comments" do
      within("#substories div.index-comments") do
        expect(page).to have_content("Recent Comments")
        expect(page).to have_link(nil, href: comment.path)
      end
    end
  end

  context "when visiting own profile" do
    before do
      sign_in user
      visit "/user3000"
    end

    it "shows the header", js: true do
      within("h1") { expect(page).to have_content(user.name) }
      within(".profile-details") do
        expect(page).to have_button("EDIT PROFILE")
      end
    end

    it "shows user's articles" do
      within(".single-article") do
        expect(page).to have_content(article.title)
        expect(page).not_to have_content(other_article.title)
      end
    end

    it "shows user's comments" do
      within("#substories div.index-comments") do
        expect(page).to have_content("Recent Comments")
        expect(page).to have_link(nil, href: comment.path)
      end
    end
  end
end
