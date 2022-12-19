# We allow content creators to "tag" their content.  This model helps
# define what we mean when we "tag" something.
#
# These tags can be arbitrary or supported (e.g. `tag.supported ==
# true`). Some tags have moderators.  These tags can create a
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

  attr_accessor :tag_moderator_id, :remove_moderator_id

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
  include StringAttributeCleaner.nullify_blanks_for(:alias_for)
  ALLOWED_CATEGORIES = %w[uncategorized language library tool site_mechanic location subcommunity].freeze
  HEX_COLOR_REGEXP = /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/

  belongs_to :badge, optional: true

  has_many :articles, through: :taggings, source: :taggable, source_type: "Article"
  has_many :display_ads, through: :taggings, source: :taggable, source_type: "DisplayAd"

  mount_uploader :profile_image, ProfileImageUploader
  mount_uploader :social_image, ProfileImageUploader

  validates :text_color_hex, format: HEX_COLOR_REGEXP, allow_nil: true
  validates :bg_color_hex, format: HEX_COLOR_REGEXP, allow_nil: true
  validates :category, presence: true, inclusion: { in: ALLOWED_CATEGORIES }

  validate :validate_alias_for, if: :alias_for?
  validate :validate_name, if: :name?

  before_validation :evaluate_markdown
  before_validation :tidy_short_summary
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

  # @return [String]
  #
  # @see ApplicationRecord#class_name
  def class_name
    self.class.name
  end

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
    errors.add(:name, I18n.t("errors.messages.too_long", count: 30)) if name.length > 30
    # [:alnum:] is not used here because it supports diacritical characters.
    # If we decide to allow diacritics in the future, we should replace the
    # following regex with [:alnum:].
    errors.add(:name, I18n.t("errors.messages.contains_prohibited_characters")) unless name.match?(/\A[[:alnum:]]+\z/i)
  end

  # While this non-end user facing flag is "in play", our goal is to say that when it's "false"
  # we'll preserve existing behavior.  And when true, we're testing out new behavior.  This way we
  # can push up changes and refactor towards improvements without unleashing a large pull request
  # with many tendrils.
  #
  # @return [TrueClass] when we want to favor the "accessible_name" for the tag.
  # @return [FalseClass] when we will use the all lower case name for the tag.
  #
  # @note This is a feature flag we're using to ease refactoring towards accessible tag labels.
  #       Eventually, we would remove this method and always favor accessible names.
  #
  # @todo When we've fully tested this feature, we'll allways return true, and can effectively
  #       remove it.
  def self.favor_accessible_name_for_tag_label?
    FeatureFlag.enabled?(:favor_accessible_name_for_tag_label)
  end

  # @note In the future we envision always favoring pretty name over the given name.
  #
  # @todo When we "rollout this feature" remove the guard clause and adjust the corresponding spec.
  def accessible_name
    return name unless self.class.favor_accessible_name_for_tag_label?

    pretty_name.presence || name
  end

  def errors_as_sentence
    errors.full_messages.to_sentence
  end

  # @param follower [#id, #class_name] An object who's class "acts_as_follower" (e.g. a User).
  #
  # @return [ActiveRecord::Relation<Tag>] with the "points" attribute and limited field selection
  #         for presenting followed tags on the front-end.
  #
  # @note This method will also add the follower's "points" for the given tag.  In the
  #       ActiveRecord::Base implementation, we can add "virtual" attributes by including them in
  #       the select statement (as shown in the method implementation).  Doing this can sometimes
  #       result in a surprise, so you may want to consider casting the results into a well-defined
  #       data structure.  But then you might be looking at implementing the DataMapper pattern.
  #
  #
  # @example
  #   Below is the SQL generated:
  #
  #   ```sql
  #     SELECT tags.*, "followings"."points"
  #       FROM "tags"
  #         INNER JOIN "follows" "followings"
  #           ON "followings"."followable_type" = 'ActsAsTaggableOn::Tag'
  #           AND "followings"."followable_id" = "tags"."id"
  #       WHERE "followings"."follower_id" = 1
  #          AND "followings"."follower_type" = 'User'
  #     ORDER BY "tags"."hotness_score" DESC
  #   ```
  #
  # @see Tag#points
  #
  # @see UserDecorator::CACHED_TAGGED_BY_USER_ATTRIBUTES for discussion on why we're selecting this.
  #
  # @todo should we sort by hotness score?  Wouldn't the user's points make more sense?
  def self.followed_tags_for(follower:)
    Tag
      .select(
        "tags.bg_color_hex",
        "tags.hotness_score",
        "tags.id",
        "tags.name",
        "tags.text_color_hex",
        "followings.points",
      )
      .joins(:followings)
      .where("followings.follower_id" => follower.id, "followings.follower_type" => follower.class_name)
      .order(hotness_score: :desc)
  end

  # What's going on here?  There are times where we want our "Tag" object to have a "points"
  # attribute; for example when we want to render the tags a user is following and the points we've
  # calculated for that following.  (Yes that is a short-circuit and we could perhaps make a more
  # appropriate data structure, but that's our current state as of <2022-01-21 Fri>.)
  #
  # @see Tag.followed_tags_for for details on injecting the "points" attribute on the Tag
  #      object's attributes.
  #
  # @note The @points can be removed when we remove `attr_writer :points`
  #
  # @see Follows::UpdatePointsWorker for details on how :points are calculated from the :explicit_points
  # @see Tag#explicit_points
  # @see Tag#implicit_points
  def points
    (attributes["points"] || @points || 0)
  end

  # @!attribute [rw] explicit_points
  #
  #   These values are set by the user.  The `Follows::UpdatePointsWorker` runs calculations on the
  #   points to determine the explicit points.
  #
  #   @see ./app/views/dashboards/following_tags.html.erb

  # @!attribute [rw] implicit_points
  #
  #   This value is calculated.  The `Follows::UpdatePointsWorker` runs calculations on the points
  #   to determine the explicit points.
  #
  #   @see ./app/views/dashboards/following_tags.html.erb

  # @deprecated [@jeremyf] in moving towards adding the :points attribute via ActiveRecord query
  #             instantiation, this is not needed.  But it's here for later removal
  attr_writer :points

  private

  def tidy_short_summary
    self.short_summary = ActionController::Base.helpers.strip_tags(short_summary)
  end

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
    #     AND (articles.published_at > 7.days.ago)
    #
    # Due to the construction of the query, there will be one entry.
    # Furthermore, we need to first convert to an array then call
    # `.first`.  The ActiveRecord query handler is ill-prepared to
    # call "first" on this.
    score_attributes = Article.cached_tagged_with(name)
      .where("articles.published_at > ?", 7.days.ago)
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

    errors.add(:tag, I18n.t("models.tag.alias_for"))
  end

  def pound_it
    text_color_hex&.prepend("#") unless text_color_hex&.starts_with?("#") || text_color_hex.blank?
    bg_color_hex&.prepend("#") unless bg_color_hex&.starts_with?("#") || bg_color_hex.blank?
  end

  def mark_as_updated
    self.updated_at = Time.current # Acts-as-taggable didn't come with this by default
  end
end
