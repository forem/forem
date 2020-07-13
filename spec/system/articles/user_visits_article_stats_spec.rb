require "rails_helper"

RSpec.describe "Viewing an article stats", type: :system, js: true do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }

  it "shows stats for pro users by clicking on the stats button" do
    path = "/#{user.username}/#{article.slug}/stats"
    allow(user).to receive(:pro?).and_return(true)
    sign_in user
    visit path

    expect(page).to have_current_path(path)
    expect(page).to have_selector(".summary-stats")
  end
end
