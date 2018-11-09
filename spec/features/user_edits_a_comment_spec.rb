require "rails_helper"

RSpec.describe "Editing A Comment", type: :feature, js: true do
  let(:user) { create(:user) }
  let(:article) { create(:article, show_comments: true) }
  let(:new_comment_text) { Faker::Lorem.paragraph }

  before do
    create(:comment, commentable: article, user: user, body_markdown: Faker::Lorem.paragraph)
    sign_in user
  end

  def assert_updated
    expect(page).to have_css("textarea[autofocus='autofocus']")
    fill_in "text-area", with: new_comment_text
    click_button("SUBMIT")
    expect(page).to have_text(new_comment_text)
  end

  context "when user edits comment on the bottom of the article" do
    it "updates" do
      visit article.path.to_s
      click_link("EDIT")
      assert_updated
    end
  end

  context "when user edits via permalinks" do
    it "updates" do
      user.reload
      visit user.comments.last.path.to_s
      click_link("EDIT")
      assert_updated
    end
  end
end
