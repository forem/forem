require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210712162220_backfill_section_column_for_navigation_links.rb",
)

describe DataUpdateScripts::BackfillSectionColumnForNavigationLinks do
  it "backfills relevant navigation links with 'other' section" do
    other_navigation_link = create(:navigation_link, url: "/privacy")

    expect do
      described_class.new.run
    end.to change { other_navigation_link.reload.section }.from("default").to("other")
  end

  it "leaves irrelevant navigation links unchanged" do
    default_navigation_link = create(:navigation_link, url: "/readinglist")

    expect do
      described_class.new.run
    end.not_to change { default_navigation_link.reload.section }
  end
end
