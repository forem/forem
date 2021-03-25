require_relative "../lib/acts_as_taggable_on/tag"

class Tag < ActsAsTaggableOn::Tag
  self.ignored_columns = ["buffer_profile_id_code"].freeze

  attr_accessor :points, :tag_moderator_id, :remove_moderator_id

  acts_as_followable
  resourcify

  # This model doesn't inherit from ApplicationRecord so this has to be included
  include Purgeable
  include Searchable

  include PgSearch::Model

  ALLOWED_CATEGORIES = %w[uncategorized language library tool site_mechanic location subcommunity].freeze
  HEX_COLOR_REGEXP = /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/.freeze

  belongs_to :badge, optional: true
  belongs_to :mod_chat_channel, class_name: "ChatChannel", optional: true

  has_many :articles, through: :taggings, source: :taggable, source_type: "Article"

  has_one :sponsorship, as: :sponsorable, inverse_of: :sponsorable, dependent: :destroy

  mount_uploader :profile_image, ProfileImageUploader
  mount_uploader :social_image, ProfileImageUploader

  validates :text_color_hex, format: HEX_COLOR_REGEXP, allow_nil: true
  validates :bg_color_hex, format: HEX_COLOR_REGEXP, allow_nil: true
  validates :category, presence: true, inclusion: { in: ALLOWED_CATEGORIES }

  validate :validate_alias_for, if: :alias_for?
  validate :validate_name, if: :name?

  before_validation :evaluate_markdown
  before_validation :pound_it

  before_save :calculate_hotness_score
  before_save :mark_as_updated

  after_commit :bust_cache
  after_commit :index_to_elasticsearch, on: %i[create update]
  after_commit :sync_related_elasticsearch_docs, on: [:update]
  after_commit :remove_from_elasticsearch, on: [:destroy]

  pg_search_scope :search_by_name,
                  against: :name,
                  using: { tsearch: { prefix: true } }

  scope :eager_load_serialized_data, -> {}

  SEARCH_SERIALIZER = Search::TagSerializer
  SEARCH_CLASS = Search::Tag
  DATA_SYNC_CLASS = DataSync::Elasticsearch::Tag

  # possible social previews templates for articles with a particular tag
  def self.social_preview_templates
    Rails.root.join("app/views/social_previews/articles").children.map { |ch| File.basename(ch, ".html.erb") }
  end

  def submission_template_customized(param_0 = nil)
    submission_template&.gsub("PARAM_0", param_0)
  end

  def tag_moderator_ids
    User.with_role(:tag_moderator, self).order(id: :asc).ids
  end

  def self.valid_categories
    ALLOWED_CATEGORIES
  end

  def self.aliased_name(word)
    tag = find_by(name: word.downcase)
    return unless tag

    tag.alias_for.presence || tag.name
  end

  def self.find_preferred_alias_for(word)
    find_by(name: word.downcase)&.alias_for.presence || word.downcase
  end

  def validate_name
    errors.add(:name, "is too long (maximum is 30 characters)") if name.length > 30
    # [:alnum:] is not used here because it supports diacritical characters.
    # If we decide to allow diacritics in the future, we should replace the
    # following regex with [:alnum:].
    errors.add(:name, "contains non-ASCII characters") unless name.match?(/\A[[a-z0-9]]+\z/i)
  end

  def errors_as_sentence
    errors.full_messages.to_sentence
  end

  private

  def evaluate_markdown
    self.rules_html = MarkdownProcessor::Parser.new(rules_markdown).evaluate_markdown
    self.wiki_body_html = MarkdownProcessor::Parser.new(wiki_body_markdown).evaluate_markdown
  end

  def calculate_hotness_score
    self.hotness_score = Article.tagged_with(name)
      .where("articles.featured_number > ?", 7.days.ago.to_i)
      .sum do |article|
        (article.comments_count * 14) + article.score + rand(6) + ((taggings_count + 1) / 2)
      end
  end

  def bust_cache
    Tags::BustCacheWorker.perform_async(name)
  end

  def validate_alias_for
    return if Tag.exists?(name: alias_for)

    errors.add(:tag, "alias_for must refer to an existing tag")
  end

  def pound_it
    text_color_hex&.prepend("#") unless text_color_hex&.starts_with?("#") || text_color_hex.blank?
    bg_color_hex&.prepend("#") unless bg_color_hex&.starts_with?("#") || bg_color_hex.blank?
  end

  def mark_as_updated
    self.updated_at = Time.current # Acts-as-taggable didn't come with this by default
  end
end
