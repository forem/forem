require "rails_helper"

describe "Views an article", type: :system do
  let(:user) { create(:user) }
  let!(:article) { create(:article, user: user) }

  before do
    create_list(:comment, 3, commentable: article)
    sign_in user
  end

  it "shows comments", js: true do
    visit article.path
    expect(page).to have_selector(".single-comment-node", visible: true, count: 3)
  end
end
