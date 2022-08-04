require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220804135957_backfill_navigation_links_column_display_to.rb",
)

describe DataUpdateScripts::BackfillNavigationLinksColumnDisplayTo do
  it "backfills relevant navigation links with 'logged_in' value for display_to" do
    logged_in_navigation_link = create(:navigation_link, url: "/privacy", display_only_when_signed_in: true,
                                                         display_to: "all")

    expect do
      described_class.new.run
    end.to change { logged_in_navigation_link.reload.display_to }.from("all").to("logged_in")
  end

  it "leaves visible-to-all navigation links unchanged" do
    visible_to_all_navigation_link = create(:navigation_link, url: "/readinglist", display_only_when_signed_in: false,
                                                              display_to: "all")

    expect do
      described_class.new.run
    end.not_to change { visible_to_all_navigation_link.reload.display_to }
  end
end
