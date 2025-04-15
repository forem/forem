class Listing < ApplicationRecord
  # We used to use both "classified listing" and "listing" throughout the app.
  # We standardized on the latter, but keeping the table name was easier.
  self.table_name = "classified_listings"

  attr_accessor :action

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

  validates :organization_id, presence: true, unless: :user_id?

  validates :title, presence: true, length: { maximum: 128 }
  validates :body_markdown, presence: true, length: { maximum: 400 }
  validates :location, length: { maximum: 32 }
  validate :restrict_markdown_input
  validate :validate_tags

  scope :published, -> { where(published: true) }

  # NOTE: we still need to use the old column name for the join query
  scope :in_category, lambda { |slug|
    joins(:listing_category).where("classified_listing_categories.slug" => slug)
  }

  delegate :cost, to: :listing_category

  # As part of making listings "optional", this is the current place to go for the answer "Is the
  # Listing feature enabled?"  This approach will get us quite far, at least up until we flip this
  # into a plugin (e.g. we won't be able to guarantee that we have the constant :Listing in the Ruby
  # object space).
  #
  # @note As of <2022-01-28 Fri>, the assumption is that everyone will have this feature enabled.
  #       In part because marking this feature as disabled won't yet properly disable all aspects of
  #       the feature.
  #
  # @see https://github.com/forem/rfcs/issues/291 for discussion and rollout strategy
  # @see FeatureFlag.accessible?
  #
  # @return [TrueClass] if the Listing is enabled for this Forem
  # @return [FalseClass] if the Listing is disabled for this Forem
  def self.feature_enabled?
    FeatureFlag.enabled?(:listing_feature)
  end

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

  def path
    "/listings/#{category}/#{slug}"
  end

  def natural_expiration_date
    (bumped_at || created_at) + 30.days
  end

  def publish
    update(published: true)
  end

  def unpublish
    update(published: false)
  end

  def bump
    update(bumped_at: Time.current)
  end

  def clear_cache
    Listings::BustCacheWorker.perform_async(id)
  end

  # First tries to purchase the listing with the org's credit. IF that doesn't
  # work it tries to charge the user instead. The purchasers will be yielded
  # to the provided block so it can be used for further processing.
  def purchase(user)
    purchaser = [organization, user].detect { |who| who&.enough_credits?(cost) }
    return false unless purchaser

    yield purchaser
    true
  end

  private

  def evaluate_markdown
    self.processed_html = MarkdownProcessor::Parser.new(body_markdown).evaluate_listings_markdown
  end

  def modify_inputs
    temp_tags = tag_list
    self.tag_list = [] # overwrite any existing tag with those from the front matter
    tag_list.add(temp_tags, parser: ActsAsTaggableOn::TagParser)
    self.body_markdown = body_markdown.to_s.gsub("\r\n", "\n")
  end

  def restrict_markdown_input
    markdown_string = body_markdown.to_s
    if markdown_string.scan(/(?=\n)/).count > 12
      errors.add(:body_markdown, I18n.t("models.listing.too_many_linebreaks"))
    end
    errors.add(:body_markdown, I18n.t("models.listing.image_not_allowed")) if markdown_string.include?("![")
    errors.add(:body_markdown, I18n.t("models.listing.liquid_not_allowed")) if markdown_string.include?("{% ")
  end

  def validate_tags
    errors.add(:tag_list, I18n.t("models.listing.too_many_tags")) if tag_list.length > 8
  end

  def create_slug
    self.slug = "#{title.downcase.parameterize.delete('_')}-#{rand(100_000).to_s(26)}"
  end
end
