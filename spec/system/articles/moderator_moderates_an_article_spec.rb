require "rails_helper"

RSpec.describe "Views an article", type: :system do
  let(:user) { create(:user) }
  let(:moderator) { create(:user, :trusted) }
  let(:article) { create(:article, :with_notification_subscription, user: user) }
  let(:timestamp) { "2019-03-04T10:00:00Z" }

  before do
    sign_in moderator
    visit "/#{user.username}/#{article.slug}/mod"
  end

  it "shows an article", js: true do
    visit "/#{user.username}/#{article.slug}"

    expect(page).to have_content(article.title)
  end

  it "lets moderators visit /mod", js: true do
    visit "/#{user.username}/#{article.slug}/mod"

    expect(page).to have_selector('button[data-category="thumbsdown"][data-reactable-type="Article"]')
    expect(page).to have_selector('button[data-category="vomit"][data-reactable-type="Article"]')
    expect(page).to have_selector('button[data-category="vomit"][data-reactable-type="User"]')
    expect(page).to have_selector("button.level-rating-button")
  end

  it "shows hidden comments on /mod" do
    commentor = create(:user)
    create(:comment, commentable: article, user: commentor, hidden_by_commentable_user: true)
    visit "/#{user.username}/#{article.slug}/mod"
    expect(page).to have_content("Hidden Comments")
    expect(page).to have_selector("ul#hidden-comments")
  end
end
