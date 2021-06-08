require "rails_helper"

RSpec.describe "Viewing an article stats", type: :system, js: true do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }

  it "shows stats for a user by clicking on the stats button" do
    path = "/#{user.username}/#{article.slug}/stats"
    sign_in user
    visit path

    expect(page).to have_current_path(path)
    expect(page).to have_selector(".summary-stats")
  end
end
