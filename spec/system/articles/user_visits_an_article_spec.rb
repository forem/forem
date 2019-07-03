require "rails_helper"

RSpec.describe "Views an article", type: :system do
  let_it_be(:user) { create(:user) }
  let_it_be(:article, reload: true) { create(:article, :with_notification_subscription, user: user) }
  let(:timestamp) { "2019-03-04T10:00:00Z" }

  before do
    sign_in user
  end

  it "shows an article" do
    visit "/#{user.username}/#{article.slug}"
    expect(page).to have_content(article.title)
  end

  it "shows comments", js: true do
    create_list(:comment, 3, commentable: article)
    visit "/#{user.username}/#{article.slug}"
    expect(page).to have_selector(".single-comment-node", visible: true, count: 3)
  end

  context "when showing the date" do
    before do
      article.update_column(:published_at, Time.zone.parse(timestamp))
    end

    it "shows the readable publish date", js: true do
      visit "/#{user.username}/#{article.slug}"
      expect(page).to have_selector("article time", text: "Mar 4")
    end

    it "embeds the published timestamp" do
      visit "/#{user.username}/#{article.slug}"
      selector = "article time[datetime='#{timestamp}']"
      expect(page).to have_selector(selector)
    end
  end
end
