require "rails_helper"

RSpec.describe "Link on tags for post in notifications", type: :system do
  let(:js_tag) { create(:tag, name: "javascript") }
  let(:ruby_tag) { create(:tag, name: "ruby") }

  let(:article) do
    create(:article, tags: "javascript, ruby")
  end

  context "when user hasn't logged in" do
    before do
      visit "/dashboard"
    end

    it "shows the sign-with page", js: true, percy: true do
      Percy.snapshot(page, name: "Logged out user: sign-in page")
      expect(page).to have_content(/Sign In With/i, count: 2)
    end
  end

  context "when logged in user" do
    before do
      sign_in article.user
    end

    it "shows articles with tags", js: true, percy: true do
      visit "/dashboard"

      Percy.snapshot(page, name: "Logged in user: dashboard")
      expect(page).to have_selector(".spec__dashboard-story", count: 1)
      expect(page).to have_link("#ruby", href: "/t/ruby")
      expect(page).to have_link("#javascript", href: "/t/javascript")
    end
  end
end
