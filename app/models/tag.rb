class Tag < ActsAsTaggableOn::Tag
  attr_accessor :points

  include AlgoliaSearch
  acts_as_followable
  resourcify

  NAMES = %w[
    beginners career computerscience git go java javascript react vue webassembly
    linux productivity python security webdev css php laravel opensource npm a11y
    ruby cpp dotnet swift testing devops vim kotlin rust elixir graphql blockchain sre
    scala vscode docker kubernetes aws android ios angular csharp typescript django rails
    clojure ubuntu elm gamedev flutter dart bash machinelearning sql
  ].freeze

  ALLOWED_CATEGORIES = %w[uncategorized language library tool site_mechanic location subcommunity].freeze

  attr_accessor :tag_moderator_id, :remove_moderator_id

  belongs_to :badge, optional: true
  has_one :sponsorship, as: :sponsorable, inverse_of: :sponsorable, dependent: :destroy

  mount_uploader :profile_image, ProfileImageUploader
  mount_uploader :social_image, ProfileImageUploader

  validates :text_color_hex,
            format: /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/, allow_nil: true
  validates :bg_color_hex,
            format: /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/, allow_nil: true
  validates :category, inclusion: { in: ALLOWED_CATEGORIES }

  validate :validate_alias
  before_validation :evaluate_markdown
  before_validation :pound_it
  before_save :calculate_hotness_score
  after_save :bust_cache
  before_save :mark_as_updated

  algoliasearch per_environment: true do
    attribute :name, :bg_color_hex, :text_color_hex, :hotness_score, :supported, :short_summary
    attributesForFaceting [:supported]
    customRanking ["desc(hotness_score)"]
    searchableAttributes %w[name short_summary]
  end

  def submission_template_customized(param_0 = nil)
    submission_template&.gsub("PARAM_0", param_0)
  end

  def tag_moderator_ids
    User.with_role(:tag_moderator, self).order("id ASC").pluck(:id)
  end

  def self.bufferized_tags
    Rails.cache.fetch("bufferized_tags_cache", expires_in: 2.hours) do
      where.not(buffer_profile_id_code: nil).pluck(:name)
    end
  end

  def self.valid_categories
    ALLOWED_CATEGORIES
  end

  private

  def evaluate_markdown
    self.rules_html = MarkdownParser.new(rules_markdown).evaluate_markdown
    self.wiki_body_html = MarkdownParser.new(wiki_body_markdown).evaluate_markdown
  end

  def calculate_hotness_score
    self.hotness_score = Article.tagged_with(name).
      where("articles.featured_number > ?", 7.days.ago.to_i).
      map do |a|
        (a.comments_count * 14) + (a.reactions_count * 4) + rand(6) + ((taggings_count + 1) / 2)
      end.
      sum
  end

  def bust_cache
    Tags::BustCacheJob.perform_later(name)
  end

  def validate_alias
    errors.add(:tag, "alias_for must refer to existing tag") if alias_for.present? && !Tag.find_by(name: alias_for)
  end

  def pound_it
    text_color_hex&.prepend("#") unless text_color_hex&.starts_with?("#") || text_color_hex.blank?
    bg_color_hex&.prepend("#") unless bg_color_hex&.starts_with?("#") || bg_color_hex.blank?
  end

  def mark_as_updated
    self.updated_at = Time.current # Acts-as-taggable didn't come with this by default
  end
end
