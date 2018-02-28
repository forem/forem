require "rails_helper"

feature "Creating Comment" do
  let(:user) { create(:user) }
  let(:raw_comment) { Faker::Lorem.paragraph }
  let(:article) do
    create(:article, user_id: user.id, show_comments: true)
  end

  background do
    login_via_session_as user
  end

  # scenario "User fills out comment box normally" do
  #   visit article.path.to_s
  #   fill_in "text-area", with: raw_comment
  #   click_button("SUBMIT")
  #   expect(page).to have_css(".comment-action-buttons")
  #   expect(page).to have_text(raw_comment)
  # end

  # scenario "User replies to a comment" do
  #   create(:comment, commentable_id: article.id, user_id: user.id)
  #   visit article.path.to_s
  #   find(".toggle-reply-form").click
  #   fill_in "text-area", with: raw_comment
  #   click_button("SUBMIT")
  #   expect(page).to have_text(raw_comment)
  # end
end
