require "rails_helper"

RSpec.describe Articles::Feeds::Basic, type: :system, js: true do
  let(:user) { create(:user) }
  let(:hot_story) do
    create(:article, :past, hotness_score: 1000, score: 1000, past_published_at: 3.hours.ago)
  end

  before do
    create(:article, hotness_score: 10)
  end

  context "with a user" do
    let(:feed) { described_class.new(user: user, number_of_articles: 100, page: 1) }

    it "doesn't display blocked articles", type: :system, js: true do
      selector = "article[data-content-user-id='#{hot_story.user_id}']"
      sign_in user
      visit root_path
      expect(page).to have_selector(selector, visible: :visible)
      create(:user_block, blocker: user, blocked: hot_story.user, config: "default")
      visit root_path
      expect(page).to have_selector(selector, visible: :hidden)
    end
  end
end
