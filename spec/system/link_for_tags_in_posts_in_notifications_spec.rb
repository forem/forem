require "rails_helper"

RSpec.describe "Link on tags for post in notifications" do
  let(:article) do
    create(:article, tags: "javascript, ruby")
  end

  context "when user hasn't logged in" do
    before do
      visit "/dashboard"
    end

    it "shows the sign-with page" do
      Authentication::Providers.enabled.each do |provider_name|
        provider = Authentication::Providers.get!(provider_name)

        expect(page).to have_content("Continue with #{provider.official_name}")
      end
    end
  end

  context "when logged in user" do
    before do
      sign_in article.user
    end

    it "shows articles" do
      visit "/dashboard"
      expect(page).to have_css(".spec__dashboard-story", count: 1)
    end
  end
end
