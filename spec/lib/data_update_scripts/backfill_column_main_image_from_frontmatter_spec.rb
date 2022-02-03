require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220120052641_backfill_column_main_image_from_frontmatter.rb",
)

describe DataUpdateScripts::BackfillColumnMainImageFromFrontmatter do
  let(:article_without_image) { create(:article, with_main_image: false) }
  let(:article_main_image) { create(:article, with_main_image: true) }
  let(:article_markdown_image) do
    create(:article,
           body_markdown: "---\ntitle: hey hey hahuu\npublished: false\ncover_image: \n---\nYo ho ho#{rand(100)}")
  end

  before do
    article_without_image
    article_main_image
    article_markdown_image
  end

  it "set main_image_from_frontmatter to true only for articles with cover_image in body_markdown" do
    described_class.new.run
    expect(article_without_image.reload.main_image_from_frontmatter).to be false
    expect(article_main_image.reload.main_image_from_frontmatter).to be false
    expect(article_markdown_image.reload.main_image_from_frontmatter).to be true
  end
end
