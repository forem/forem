require "rails_helper"

RSpec.describe "Deleting Comment", type: :system, js: true do
  let(:user) { create(:user) }
  let(:raw_comment) { Faker::Lorem.paragraph }
  let(:article) do
    create(:article, user_id: user.id, show_comments: true)
  end
  let(:comment) { create(:comment, commentable: article, commentable_type: "Article", user: user) }

  before do
    sign_in user
  end

  it "works" do
    visit "/"
    visit "#{comment.path}/delete_confirm"

    wait_for_javascript

    click_button("Delete")
    expect(page).to have_current_path(article.path)
  end
end
