class ClassifiedListing < ApplicationRecord
  include Searchable

  SEARCH_SERIALIZER = Search::ClassifiedListingSerializer
  SEARCH_CLASS = Search::ClassifiedListing

  attr_accessor :action

  # This allows to create a listing from a catgory string.
  # TODO: [mkohl] refactor once column was dropped.
  before_validation :assign_classified_listing_category

  belongs_to :classified_listing_category
  belongs_to :user
  belongs_to :organization, optional: true
  before_save :evaluate_markdown
  before_create :create_slug
  before_validation :modify_inputs
  after_commit :index_to_elasticsearch, on: %i[create update]
  after_commit :remove_from_elasticsearch, on: [:destroy]
  acts_as_taggable_on :tags
  has_many :credits, as: :purchase, inverse_of: :purchase, dependent: :nullify

  validates :user_id, presence: true
  validates :organization_id, presence: true, unless: :user_id?

  validates :title, presence: true, length: { maximum: 128 }
  validates :body_markdown, presence: true, length: { maximum: 400 }
  validates :location, length: { maximum: 32 }
  validate :restrict_markdown_input
  validate :validate_tags
  validate :validate_category

  scope :published, -> { where(published: true) }

  # TODO: refactor this class method block
  def self.select_options_for_categories
    ClassifiedListingCategory.select(:id, :name, :cost).map do |cl|
      ["#{cl.name} (#{cl.cost} #{'Credit'.pluralize(cl.cost)})", cl.id]
    end
  end

  def self.categories_for_display
    ClassifiedListingCategory.pluck(:slug, :name).map do |slug, name|
      { slug: slug, name: name }
    end
  end

  def self.categories_available
    ClassifiedListingCategory.all.each_with_object({}) do |cat, h|
      h[cat.slug] = cat.attributes.slice("cost", "name", "rules")
    end.deep_symbolize_keys
  end

  def category
    classified_listing_category&.slug
  end

  def cost
    @cost = classified_listing_category&.cost ||
      ClassifiedListingCategory.select(:cost).find_by(slug: category)&.cost
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

  private

  def evaluate_markdown
    self.processed_html = MarkdownParser.new(body_markdown).evaluate_listings_markdown
  end

  def modify_inputs
    ActsAsTaggableOn::Taggable::Cache.included(ClassifiedListing)
    ActsAsTaggableOn.default_parser = ActsAsTaggableOn::TagParser
    self.category = category.to_s.downcase
    self.body_markdown = body_markdown.to_s.gsub(/\r\n/, "\n")
  end

  def restrict_markdown_input
    markdown_string = body_markdown.to_s
    errors.add(:body_markdown, "has too many linebreaks. No more than 12 allowed.") if markdown_string.scan(/(?=\n)/).count > 12
    errors.add(:body_markdown, "is not allowed to include images.") if markdown_string.include?("![")
    errors.add(:body_markdown, "is not allowed to include liquid tags.") if markdown_string.include?("{% ")
  end

  def validate_category
    categories = ClassifiedListingCategory.pluck(:slug)
    errors.add(:category, "not a valid category") unless category.in?(categories)
  end

  def validate_tags
    errors.add(:tag_list, "exceed the maximum of 8 tags") if tag_list.length > 8
  end

  def create_slug
    self.slug = "#{title.downcase.parameterize.delete('_')}-#{rand(100_000).to_s(26)}"
  end

  def assign_classified_listing_category
    return if classified_listing_category_id.present?

    category = ClassifiedListingCategory.find_by(slug: attributes["category"])
    return unless category

    self.category = category.slug
    self.classified_listing_category_id = category.id
  end
end
