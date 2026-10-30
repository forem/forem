require "rails_helper"

RSpec.describe "Moderator moderates an article" do
  let(:user) { create(:user) }
  let(:moderator) { create(:user, :trusted) }
  let(:article) { create(:article, user: user, with_tags: false) }

  before do
    sign_in moderator
  end

  it "lets moderators visit /mod and see moderation controls and hidden comments", :aggregate_failures do
    create(:comment, commentable: article, user: user, hidden_by_commentable_user: true)
    visit "/#{user.username}/#{article.slug}/mod"
    expect(page).to have_css('button[data-category="thumbsdown"][data-reactable-type="Article"]')
    expect(page).to have_css('button[data-category="vomit"][data-reactable-type="Article"]')
    expect(page).to have_css('button[data-category="vomit"][data-reactable-type="User"]')
    expect(page).to have_button(class: "level-rating-button")
    expect(page).to have_content("Hidden Comments")
    expect(page).to have_css("ul#hidden-comments")
  end
end
