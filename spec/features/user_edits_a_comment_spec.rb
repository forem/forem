require "rails_helper"

RSpec.describe "Editing Comment", type: :feature, js: true do
  let(:user) { create(:user) }
  let(:article) { create(:article, show_comments: true) }
  let(:raw_comment) { Faker::Lorem.paragraph }
  let(:new_comment_text) { Faker::Lorem.paragraph }
  let(:comment) do
    create(:comment, commentable_id: article.id, user_id: user.id, body_markdown: raw_comment)
  end

  before do
    sign_in user
    comment
  end

  describe "User edits their own comment on the bottom of the article" do
    it "User clicks the edit button and autofocuses to the text field" do
      visit article.path.to_s
      find(:xpath, "//a[@class='edit-butt' and text()='EDIT']").click
      expect(page).to have_css("textarea[autofocus='autofocus']")
    end

    it "User submits a new edit on their comment" do
      visit article.path.to_s
      find(:xpath, "//a[@class='edit-butt' and text()='EDIT']").click
      fill_in "text-area", with: new_comment_text
      click_button("SUBMIT")
      expect(page).to have_text(new_comment_text)
    end
  end

  describe "User edits comment their own comment on their permalink page" do
    it "User clicks the edit button and autofocuses to the text field" do
      visit comment.path.to_s
      find(:xpath, "//a[@class='edit-butt' and text()='EDIT']").click
      expect(page).to have_css("textarea[autofocus='autofocus']")
    end
  end
end
