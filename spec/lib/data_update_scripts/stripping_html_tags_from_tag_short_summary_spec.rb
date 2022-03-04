require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220121114445_stripping_html_tags_from_tag_short_summary.rb",
)

describe DataUpdateScripts::StrippingHtmlTagsFromTagShortSummary do
  it "updates a tag that had HTML elements in it's short summary" do
    tag = create(:tag)
    tag.update_columns(short_summary: "<p>Welcome to the <a href='#'>tag</a>.</p>")
    described_class.new.run
    expect(tag.reload.short_summary).to eq("Welcome to the tag.")
  end
end
