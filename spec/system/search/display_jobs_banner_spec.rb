require "rails_helper"

RSpec.describe "Display Jobs Banner spec", type: :system, js: true, stub_elasticsearch: true do
  before do
    allow(SiteConfig).to receive(:jobs_url).and_return("www.very_cool_jobs_website.com")
  end

  context "when SiteConfig.display_jobs_banner is false" do
    it "does not show jobs banner" do
      allow(SiteConfig).to receive(:display_jobs_banner).and_return(false)
      visit "/search?q=jobs"

      expect(page).not_to have_content("Interested in joining our team?")
    end
  end

  context "when SiteConfig.display_jobs_banner is true" do
    before { allow(SiteConfig).to receive(:display_jobs_banner).and_return(true) }

    it "displays job banner for job search" do
      visit "/search?q=jobs"

      expect(page).to have_content("Interested in joining our team?")
      expect(find_link("open roles")["href"]).to include(SiteConfig.jobs_url)
    end

    it "does not display jobs banner for other searches" do
      visit "/search?q=ruby"

      expect(page).not_to have_content("Interested in joining our team?")
    end

    it "does not show jobs banner when there's no jobs_url set" do
      allow(SiteConfig).to receive(:jobs_url).and_return(nil)

      visit "/search?q=jobs"

      expect(page).not_to have_content("Interested in joining our team?")
    end
  end
end
