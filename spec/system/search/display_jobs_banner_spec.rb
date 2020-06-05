require "rails_helper"

RSpec.describe "Display Jobs Banner spec", type: :system, js: true do
  before do
    stub_request(:post, "http://www.google-analytics.com/collect")
    SiteConfig.jobs_url = "www.very_cool_jobs_website.com"
  end

  context "when SiteConfig.display_jobs_banner is false" do
    it "does not show jobs banner" do
      SiteConfig.display_jobs_banner = false
      visit "/search?q=jobs"

      expect(page).not_to have_content("Interested in joining our team?")
    end
  end

  context "when SiteConfig.display_jobs_banner is true" do
    before { SiteConfig.display_jobs_banner = true }

    it "displays job banner for job search" do
      visit "/search?q=jobs"

      expect(page).to have_content("Interested in joining our team?")
      expect(find_link("open roles")["href"]).to include(SiteConfig.jobs_url)
    end

    it "does not display jobs banner for other searches" do
      visit "/search?q=ruby"

      expect(page).not_to have_content("Interested in joining our team?")
    end
  end
end
