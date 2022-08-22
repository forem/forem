require "rails_helper"

RSpec.describe Articles::Feeds::LargeForemExperimental, type: :system, js: true do
  let(:user) { create(:user) }
  let(:second_user) { create(:user) }
  let!(:hot_story) do
    create(:article, :past, hotness_score: 1000, score: 1000, past_published_at: 3.hours.ago, user_id: second_user.id)
  end

  before do
    create(:article)
  end

  it "doesn't display blocked articles" do
    selector = "article[data-content-user-id='#{hot_story.user_id}']"
    sign_in user
    visit root_path
    expect(page).to have_selector(selector, visible: :visible)
    create(:user_block, blocker: user, blocked: hot_story.user, config: "default")
    visit root_path
    expect(page).to have_selector(selector, visible: :hidden)
  end
end
