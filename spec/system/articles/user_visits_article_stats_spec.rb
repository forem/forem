require "rails_helper"

RSpec.describe "Viewing an article stats" do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user, with_tags: false) }

  it "shows stats for a user by clicking on the stats button", :aggregate_failures do
    path = "/#{user.username}/#{article.slug}/stats"
    sign_in user
    visit path

    expect(page).to have_current_path(path)
    expect(page).to have_css(".summary-stats")
  end
end
