class ClassifiedListing < ApplicationRecord

  include AlgoliaSearch

  attr_accessor :post_as_organization, :action

  belongs_to :user, optional: true
  belongs_to :organization, optional: true

  before_save :evaluate_markdown
  before_validation :modify_inputs
  acts_as_taggable_on :tags

  validates :title, presence: true,
    length: { maximum: 128 }
  validates :body_markdown, presence: true,
                    length: { maximum: 400 }
  validate :restrict_markdown_input
  validate :validate_tags
  validate :validate_category

  algoliasearch per_environment: true do
    attribute :title, :processed_html, :bumped_at, :tag_list, :category, :id, :user_id
    attribute :author do
      { username: author.username,
        name: author.name,
        profile_image_90: ProfileImage.new(author).get(90) }
    end
    tags do
      [tag_list,
       "user_#{user_id}",
       "organization_#{organization_id}"]
    end
    attributesForFaceting [:category]
    customRanking ["desc(bumped_at)"]
    searchableAttributes %w[title processed_html tag_list]
  end

  def self.cost_by_category(category = "education")
    categories_available[category][:cost]
  end

  def author
    organization || user
  end

  def self.select_options_for_categories
    categories_available.keys.map do |key|
      ["#{categories_available[key][:name]} (#{ActionController::Base.helpers.pluralize(categories_available[key][:cost], 'Credit')})", key]
    end
  end

  def self.categories_for_display
    categories_available.keys.map do |key|
      { slug: key, name: categories_available[key][:name] }
    end
  end

  def self.categories_available
    {
      "cfp"               => { cost: 1, name: "Conference CFP", rules: "Currently open for proposals, with link to form" },
      "contractors"       => { cost: 1, name: "Contractor for Hire", rules: "You are available for hire." },
      "collabs"           => { cost: 1, name: "Contributors/Collaborators Wanted" },
      "education"         => { cost: 1, name: "Education/Courses", rules: "Educational material and/or schools/bootcamps" },
      "jobs"              => { cost: 10, name: "Job Listings", rules: "Companies offering employment right now." },
      "products"          => { cost: 1, name: "Products/Tools", rules: "Must be availabel right now" },
      "events"            => { cost: 1, name: "Upcoming Events", rules: "Live or online events with date included" },
      "misc"              => { cost: 1, name: "Miscellaneous", rules: "Must not fit in any other category." }
    }
  end

  private

  def evaluate_markdown
    parsed_markdown = MarkdownParser.new(body_markdown)
    self.processed_html = parsed_markdown.finalize
  end

  def modify_inputs
    ActsAsTaggableOn::Taggable::Cache.included(ClassifiedListing)
    ActsAsTaggableOn.default_parser = ActsAsTaggableOn::TagParser
    self.category = category.to_s.downcase
  end

  def restrict_markdown_input
    if body_markdown.to_s.scan(/(?=\n)/).count > 12
      errors.add(:body_markdown, "has too many linebreaks. No no more than 12 allowed.")
    end
    if body_markdown.to_s.include?("![")
      errors.add(:body_markdown, "is not allowed to include images.")
    end
    if body_markdown.to_s.include?("{% ")
      errors.add(:body_markdown, "is not allowed to include liquid tags.")
    end
  end

  def validate_tags
    errors.add(:tag_list, "exceed the maximum of 4 tags") if tag_list.length > 8
  end

  def validate_category
    errors.add(:category, "not a valid category") unless ClassifiedListing.categories_available[category]
  end
end
