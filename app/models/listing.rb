class Listing < ApplicationRecord
  # We used to use both "classified listing" and "listing" throughout the app.
  # We standardized on the latter, but keeping the table name was easier.
  self.table_name = "classified_listings"

  # NOTE: categories were hardcoded at first and the model was only added later.
  # The foreign_key and inverse_of options are used because of legacy table names.
  belongs_to :listing_category, inverse_of: :listings, foreign_key: :classified_listing_category_id
  belongs_to :user
  belongs_to :organization, optional: true
  before_validation :modify_inputs
  before_save :evaluate_markdown
  before_create :create_slug
  acts_as_taggable_on :tags
  has_many :credits, as: :purchase, inverse_of: :purchase, dependent: :nullify

  # --- Validations REMOVED in this step ---
  # validates :organization_id, presence: true, unless: :user_id?
  # validates :title, presence: true, length: { maximum: 128 }
  # validates :body_markdown, presence: true, length: { maximum: 400 }
  # validates :location, length: { maximum: 32 }
  # validate :restrict_markdown_input
  # validate :validate_tags
  # --- End Validations REMOVED ---

  # Keep: API might use? Check later.
  scope :published, -> { where(published: true) }

  # Wrapping the column accessor names for consistency. Aliasing did not work.
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

  def natural_expiration_date
    (bumped_at || created_at) + 30.days
  end

  def natural_expiration_date
    (bumped_at || created_at) + 30.days
  end

  def publish
    update(published: true)
  end

  # Keep: Removed in a different PR
  def unpublish
    update(published: false)
  end

  # bump method REMOVED in previous step
  # purchase method REMOVED in previous step

  def clear_cache
    Listings::BustCacheWorker.perform_async(id)
  end

  # purchase method REMOVED IN THIS STEP/PR

  private

  # Keep: Used by before_save
  def evaluate_markdown
    self.processed_html = MarkdownProcessor::Parser.new(body_markdown).evaluate_listings_markdown
  end

  # Keep: Used by before_validation
  def modify_inputs
    temp_tags = tag_list
    self.tag_list = [] # overwrite any existing tag with those from the front matter
    tag_list.add(temp_tags, parser: ActsAsTaggableOn::TagParser)
    self.body_markdown = body_markdown.to_s.gsub("\r\n", "\n")
  end

  # restrict_markdown_input method REMOVED in this step
  # validate_tags method REMOVED in this step

  # Keep: Used by before_create
  def create_slug
    self.slug = "#{title.downcase.parameterize.delete('_')}-#{rand(100_000).to_s(26)}"
  end
end