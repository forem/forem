require "rails_helper"

RSpec.describe "Deleting Comment", type: :feature, js: true, driver: :chrome do
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
    comment
    visit comment.path + "/delete_confirm"
    click_link("DELETE")
    expect(page).to redirect_to(article.path)
  end
end
