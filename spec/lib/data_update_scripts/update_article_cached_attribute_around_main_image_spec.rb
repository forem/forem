require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220203165540_update_article_cached_attribute_around_main_image.rb",
)

RSpec.describe DataUpdateScripts::UpdateArticleCachedAttributeAroundMainImage do
  let(:article_without_image) { create(:article, with_main_image: false) }
  let(:article_main_image) { create(:article, with_main_image: true) }
  let(:article_markdown_image) do
    create(:article,
           body_markdown: "---\ntitle: hey hey hahuu\npublished: false\ncover_image: \n---\nYo ho ho#{rand(100)}")
  end

  before do
    article_without_image
    article_main_image
    # Need to do the following for the script to even run.
    article_markdown_image.update_column(:main_image_from_frontmatter, false)
  end

  it "set main_image_from_frontmatter to true only for articles with cover_image in body_markdown" do
    described_class.new.run

    expect(article_without_image.reload.main_image_from_frontmatter).to be false
    expect(article_main_image.reload.main_image_from_frontmatter).to be false
    expect(article_markdown_image.reload.main_image_from_frontmatter).to be true
  end
end
