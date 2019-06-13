require "rails_helper"

RSpec.describe "Viewing an article stats", type: :system, js: true do
  let_it_be(:user) { create(:user) }
  let_it_be(:article, reload: true) { create(:article, user: user) }

  it "shows stats for pro users by clicking on the stats button" do
    path = "/#{user.username}/#{article.slug}/stats"
    user.add_role(:pro)
    sign_in user
    visit path
    expect(page).to have_current_path(path)
    expect(page).to have_selector(".summary-stats")
  end
end
