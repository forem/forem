require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20221004092644_remove_sponsorship_link_and_pages.rb",
)

describe DataUpdateScripts::RemoveSponsorshipLinkAndPages do
  it "removes any navigation links with 'sponsor' in the word" do
    create(:navigation_link, url: app_url("sponsorships").to_s)
    create(:navigation_link, url: app_url("sponsorship").to_s)
    create(:navigation_link, url: app_url("sponsors").to_s)
    create(:navigation_link, url: app_url("sponsor").to_s)
    create(:navigation_link, url: app_url("responsibilities").to_s)

    expect(NavigationLink.count).to eq(5)
    described_class.new.run
    expect(NavigationLink.count).to eq(1)
  end

  it "removes any pages with 'sponsor' in the word" do
    create(:page, slug: "sponsor")
    create(:page, slug: "sponsors")
    create(:page, slug: "sponsorship")
    create(:page, slug: "sponsorships")
    create(:page, slug: "terms_and_conditions")

    expect(Page.count).to eq(5)
    described_class.new.run
    expect(Page.count).to eq(1)
  end
end
