class Listing < ApplicationRecord
  self.table_name = "classified_listings"

  belongs_to :listing_category, inverse_of: :listings, foreign_key: :classified_listing_category_id
  belongs_to :user
  belongs_to :organization, optional: true
  acts_as_taggable_on :tags

  before_validation :modify_inputs
  before_save :evaluate_markdown
  before_create :create_slug

  scope :published, -> { where(published: true) }

  def listing_category_id
    classified_listing_category_id
  end
  def listing_category_id=(id)
    self.classified_listing_category_id = id
  end
  def category
    listing_category&.slug
  end
  def author
    organization || user
  end

  private

  def evaluate_markdown
    self.processed_html = MarkdownProcessor::Parser.new(body_markdown).evaluate_listings_markdown
  end

  def modify_inputs
    temp_tags = tag_list
    self.tag_list = []
    tag_list.add(temp_tags, parser: ActsAsTaggableOn::TagParser)
    self.body_markdown = body_markdown.to_s.gsub("\r\n", "\n")
  end

  def create_slug
    self.slug = "#{title.downcase.parameterize.delete('_')}-#{rand(100_000).to_s(26)}"
  end
end