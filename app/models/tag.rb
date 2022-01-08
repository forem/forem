# We allow content creators to "tag" their content.  This model helps
# define what we mean when we "tag" something.
#
# These tags can be arbitrary or supported (e.g. `tag.supported ==
# true`).  We allow for sponsorship of tags (see `belongs_to
# :sponsorship`).  Some tags have moderators.  These tags can create a
# defacto "sub-community" within a Forem.
#
# Sometimes we need to consolidate tags (e.g. rubyonrails and rails).
# In this case, we mark one of those tags as an alias for the other
# (via `alias_for`).  The direct tags is the "preferred" tag
# (e.g. not the alias).
#
# @note models with `acts_as_taggable_on` declarations (e.g., Article and Listing)
# @see https://developers.forem.com/technical-overview/architecture/#tags for more discussion
class Tag < ActsAsTaggableOn::Tag
  self.ignored_columns = %w[mod_chat_channel_id].freeze

  attr_accessor :points, :tag_moderator_id, :remove_moderator_id

  acts_as_followable
  resourcify

  # This model doesn't inherit from ApplicationRecord so this has to be included
  include Purgeable
  include PgSearch::Model

  # @note Even though we have a data migration script (see further
  #       comments below), as of <2022-01-04 Tue> we had 5 tags where
  #       the `alias_for == ""` (ideally they should be nil).  This
  #       change will help us achieve that goal.
  #
  # @see https://github.com/forem/forem/blob/72bb284ba73c3df8aa11525427b1dfa1ceba39df/lib/data_update_scripts/20211115154021_nullify_invalid_tag_fields.rb
  include StringAttributeCleaner.for(:alias_for)
  ALLOWED_CATEGORIES = %w[uncategorized language library tool site_mechanic location subcommunity].freeze
  HEX_COLOR_REGEXP = /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/

  belongs_to :badge, optional: true

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

  # @note Even though we have a data migration script (see further
  #       comments below), as of <2022-01-04 Tue> we had 5 tags where
  #       the alias_for was "" (ideally they should be nil).  Once we
  #       have the StringAttributeCleaner (see above) in place, and
  #       our next data migration runs, we can remove the [nil, ""]
  #       and favor `where(alias_for: nil)`.
  #
  # @see https://github.com/forem/forem/blob/72bb284ba73c3df8aa11525427b1dfa1ceba39df/lib/data_update_scripts/20211115154021_nullify_invalid_tag_fields.rb
  scope :aliased, -> { where.not(alias_for: [nil, ""]) }

  # @note We had named the concept of a tag that was an alias;
  #       however, prior to adding this scope, we didn't have a name
  #       for a non-aliased tag (aside from "not an alias").  With
  #       this scope we have a name.
  scope :direct, -> { where(alias_for: [nil, ""]) }

  pg_search_scope :search_by_name,
                  against: :name,
                  using: { tsearch: { prefix: true } }

  scope :eager_load_serialized_data, -> {}
  scope :supported, -> { where(supported: true) }

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
    errors.add(:name, I18n.t("errors.messages.contains_prohibited_characters")) unless name.match?(/\A[[:alnum:]]+\z/i)
  end

  def errors_as_sentence
    errors.full_messages.to_sentence
  end

  private

  def evaluate_markdown
    self.rules_html = MarkdownProcessor::Parser.new(rules_markdown).evaluate_markdown
    self.wiki_body_html = MarkdownProcessor::Parser.new(wiki_body_markdown).evaluate_markdown
  end

  # @note The following implementation echoes the past hotness score,
  #       but favors expected values instead of random numbers for
  #       each article (see SHA
  #       98e97e7aa8e0fc163cd7d9b063f51f01ab10a189).
  def calculate_hotness_score
    # SELECT
    #     (SUM(comments_count) * 14 + SUM(score)) AS partial_score,
    #     COUNT(id) AS article_count
    #   FROM articles
    #   WHERE
    #     (cached_tag_list ~ '[[:<:]]javascript[[:>:]]')
    #     AND (articles.featured_number > 1639594999)
    #
    # Due to the construction of the query, there will be one entry.
    # Furthermore, we need to first convert to an array then call
    # `.first`.  The ActiveRecord query handler is ill-prepared to
    # call "first" on this.
    score_attributes = Article.cached_tagged_with(name)
      .where("articles.featured_number > ?", 7.days.ago.to_i)
      .select("(SUM(comments_count) * 14 + SUM(score)) AS partial_score, COUNT(id) AS article_count")
      .to_a
      .first

    self.hotness_score =
      score_attributes.partial_score.to_i +
      (score_attributes.article_count.to_i * ((taggings_count + 6) / 2))
  end

  def bust_cache
    Tags::BustCacheWorker.perform_async(name)
    Rails.cache.delete("view-helper-#{name}/tag_colors")
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
