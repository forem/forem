class Article < ApplicationRecord
  include CloudinaryHelper
  include ActionView::Helpers
  include Reactable
  include Taggable
  include UserSubscriptionSourceable
  include PgSearch::Model
  include AlgoliaSearchable

  acts_as_taggable_on :tags
  resourcify

  include StringAttributeCleaner.nullify_blanks_for(:canonical_url, on: :before_save)
  DEFAULT_FEED_PAGINATION_WINDOW_SIZE = 50

  # When we cache an entity, either {User} or {Organization}, these are the names of the attributes
  # we cache.
  #
  # @note I would prefer that this constant were in the {Article::CachedEntity} namespace, but it
  #       didn't work out well.  Further, since Organization doesn't really know about
  #       Articles::CachedEntity, I'd rather it not "peek" into a class for which it has no
  #       knowledge.
  #
  # @note [@jeremyf] I have added the profile_image attribute, even though that's not one of the
  #       Articles::CachedEntity attributes.  This is necessary to detect the change.
  #
  # @see Articles::CachedEntity caching strategy for entity attributes
  ATTRIBUTES_CACHED_FOR_RELATED_ENTITY = %i[name profile_image profile_image_url slug username].freeze

  # admin_update was added as a hack to bypass published_at validation when admin is updating
  # TODO: [@lightalloy] remove published_at validation from the model and
  # move it to the services where the create/update takes place to avoid using hacks
  attr_accessor :publish_under_org, :admin_update
  attr_writer :series
  attr_accessor :body_url

  delegate :name, to: :user, prefix: true
  delegate :username, to: :user, prefix: true

  # touch: true was removed because when an article is updated, the associated collection
  # is touched along with all its articles(including this one). This causes eventually a deadlock.
  belongs_to :collection, optional: true

  belongs_to :organization, optional: true
  belongs_to :user
  belongs_to :subforem, optional: true

  counter_culture :user
  counter_culture :organization

  # The date that we began limiting the number of user mentions in an article.
  MAX_USER_MENTION_LIVE_AT = Time.utc(2021, 4, 7).freeze
  # all BIDI control marks (a part of them are expected to be removed during #normalize_title, but still)
  BIDI_CONTROL_CHARACTERS = /[\u061C\u200E\u200F\u202a-\u202e\u2066-\u2069]/

  MAX_TAG_LIST_SIZE = 4

  # Filter out anything that isn't a word, space, punctuation mark,
  # recognized emoji, and other auxiliary marks.
  # See: https://github.com/forem/forem/pull/16787#issuecomment-1062044359
  #
  # NOTE: try not to use hyphen (- U+002D) in comments inside regex,
  # otherwise it may break parser randomly.
  # Use underscore or Unicode hyphen (‐ U+2010) instead.
  # rubocop:disable Lint/DuplicateRegexpCharacterClassElement
  TITLE_CHARACTERS_ALLOWED = /[^
    [:word:]
    [:space:]
    [:punct:]
    \p{Sc}        # All currency symbols
    \u00a9        # Copyright symbol
    \u00ae        # Registered trademark symbol
    \u061c        # BIDI: Arabic letter mark
    \u180e        # Mongolian vowel separator
    \u200c        # Zero‐width non‐joiner, for complex scripts
    \u200d        # Zero-width joiner, for multipart emojis such as family
    \u200e-\u200f # BIDI: LTR and RTL mark (standalone)
    \u202c-\u202e # BIDI: POP, LTR, and RTL override
    \u2066-\u2069 # BIDI: LTR, RTL, FSI, and POP isolate
    \u20e3        # Combining enclosing keycap
    \u2122        # Trademark symbol
    \u2139        # Information symbol
    \u2194-\u2199 # Arrow symbols
    \u21a9-\u21aa # More arrows
    \u231a        # Watch emoji
    \u231b        # Hourglass emoji
    \u2328        # Keyboard emoji
    \u23cf        # Eject symbol
    \u23e9-\u23f3 # Various VCR‐actions emoji and clocks
    \u23f8-\u23fa # More VCR emoji
    \u24c2        # Blue circle with a white M in it
    \u25aa        # Black box
    \u25ab        # White box
    \u25b6        # VCR‐style play emoji
    \u25c0        # VCR‐style play backwards emoji
    \u25fb-\u25fe # More black and white squares
    \u2600-\u273f # Weather, zodiac, coffee, hazmat, cards, music, other misc emoji
    \u2744        # Snowflake emoji
    \u2747        # Sparkle emoji
    \u274c        # Cross mark
    \u274e        # Cross mark box
    \u2753-\u2755 # Big red and white ? emoji, big white ! emoji
    \u2757        # Big red ! emoji
    \u2763-\u2764 # Heart ! and heart emoji
    \u2795-\u2797 # Math operator emoji
    \u27a1        # Right arrow
    \u27b0        # One loop
    \u27bf        # Two loops
    \u2934        # Curved arrow pointing up to the right
    \u2935        # Curved arrow pointing down to the right
    \u2b00-\u2bff # More arrows, geometric shapes
    \u3030        # Squiggly line
    \u303d        # Either a line chart plummeting or the letter M, not sure
    \u3297        # Circled Ideograph Congratulation
    \u3299        # Circled Ideograph Secret
    \u{1f000}-\u{1ffff} # More common emoji
  ]+/m
  # rubocop:enable Lint/DuplicateRegexpCharacterClassElement

  def self.unique_url_error
    I18n.t("models.article.unique_url", email: ForemInstance.contact_email)
  end

  enum type_of: {
    full_post: 0,
    status: 1,
}

  has_one :discussion_lock, dependent: :delete

  has_many :mentions, as: :mentionable, inverse_of: :mentionable, dependent: :delete_all
  has_many :comments, as: :commentable, inverse_of: :commentable, dependent: :nullify
  has_many :context_notifications, as: :context, inverse_of: :context, dependent: :delete_all
  has_many :context_notifications_published, -> { where(context_notifications_published: { action: "Published" }) },
           as: :context, inverse_of: :context, class_name: "ContextNotification"
  has_many :feed_events, dependent: :delete_all
  has_many :notification_subscriptions, as: :notifiable, inverse_of: :notifiable, dependent: :delete_all
  has_many :notifications, as: :notifiable, inverse_of: :notifiable, dependent: :delete_all
  has_many :page_views, dependent: :delete_all
  # `dependent: :destroy` because in Poll we cascade the deletes of
  #     the poll votes, options, and skips.
  has_many :polls, dependent: :destroy
  has_many :profile_pins, as: :pinnable, inverse_of: :pinnable, dependent: :delete_all
  # `dependent: :destroy` because in RatingVote we're relying on
  #     counter_culture to do some additional tallies
  has_many :rating_votes, dependent: :destroy
  has_many :tag_adjustments
  has_many :top_comments,
           lambda {
             where(comments: { score: 11.. }, ancestry: nil, hidden_by_commentable_user: false, deleted: false)
               .order("comments.score" => :desc)
           },
           as: :commentable,
           inverse_of: :commentable,
           class_name: "Comment"

  has_many :more_inclusive_top_comments,
           lambda {
             where(comments: { score: 5.. }, ancestry: nil, hidden_by_commentable_user: false, deleted: false)
               .order("comments.score" => :desc)
           },
           as: :commentable,
           inverse_of: :commentable,
           class_name: "Comment"

  has_many :recent_good_comments,
           lambda {
             where(comments: { score: 8.. }, ancestry: nil, hidden_by_commentable_user: false, deleted: false)
               .order("comments.created_at" => :desc)
           },
           as: :commentable,
           inverse_of: :commentable,
           class_name: "Comment"

  has_many :more_inclusive_recent_good_comments,
           lambda {
             where(comments: { score: 5.. }, ancestry: nil, hidden_by_commentable_user: false, deleted: false)
               .order("comments.created_at" => :desc)
           },
           as: :commentable,
           inverse_of: :commentable,
           class_name: "Comment"

  has_many :most_inclusive_recent_good_comments,
           lambda {
             where(comments: { score: 3.. }, ancestry: nil, hidden_by_commentable_user: false, deleted: false)
               .order("comments.created_at" => :desc)
           },
           as: :commentable,
           inverse_of: :commentable,
           class_name: "Comment"

  validates :body_markdown, bytesize: {
    maximum: 800.kilobytes,
    too_long: proc { I18n.t("models.article.is_too_long") }
  }
  validates :body_markdown, length: { minimum: 0, allow_nil: false }
  validates :cached_tag_list, length: { maximum: 126 }
  validates :canonical_url,
            uniqueness: { allow_nil: true, scope: :published, message: unique_url_error },
            if: :published?
  validates :canonical_url, url: { allow_blank: true, no_local: true, schemes: %w[https http] }
  validates :comments_count, presence: true
  validates :feed_source_url,
            uniqueness: { allow_nil: true, scope: :published, message: unique_url_error },
            if: :published?
  validates :feed_source_url, url: { allow_blank: true, no_local: true, schemes: %w[https http] }
  validates :main_image, url: { allow_blank: true, schemes: %w[https http] }
  validates :main_image_background_hex_color, format: /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/
  validates :positive_reactions_count, presence: true
  validates :previous_public_reactions_count, presence: true
  validates :public_reactions_count, presence: true
  validates :rating_votes_count, presence: true
  validates :reactions_count, presence: true
  validates :slug, presence: { if: :published? }, format: /\A[0-9a-z\-_]*\z/
  validates :slug, uniqueness: { scope: :user_id }
  validates :user_subscriptions_count, presence: true
  validates :video, url: { allow_blank: true, schemes: %w[https http] }
  validates :video_closed_caption_track_url, url: { allow_blank: true, schemes: ["https"] }
  validates :video_source_url, url: { allow_blank: true, schemes: ["https"] }
  validates :video_source_url, url: { allow_blank: true, schemes: ["https"] }
  validates :video_state, inclusion: { in: %w[PROGRESSING COMPLETED] }, allow_nil: true
  validates :video_thumbnail_url, url: { allow_blank: true, schemes: %w[https http] }
  validates :clickbait_score, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0 }
  validates :compellingness_score, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0 }
  validates :max_score, numericality: { greater_than_or_equal_to: 0 }
  validate :future_or_current_published_at, on: :create
  validate :correct_published_at?, on: :update, unless: :admin_update

  validate :title_length_based_on_type_of
  validate :title_unique_for_user_past_five_minutes
  validate :restrict_attributes_with_status_types
  validate :canonical_url_must_not_have_spaces
  validate :validate_collection_permission
  validate :validate_tag
  validate :validate_video
  validate :user_mentions_in_markdown
  validate :validate_co_authors, unless: -> { co_author_ids.blank? }
  validate :validate_co_authors_must_not_be_the_same, unless: -> { co_author_ids.blank? }
  validate :validate_co_authors_exist, unless: -> { co_author_ids.blank? }

  before_validation :set_markdown_from_body_url, if: :body_url?
  before_validation :evaluate_markdown, :create_slug, :set_published_date
  before_validation :normalize_title
  before_validation :replace_blank_title_for_status
  before_validation :remove_prohibited_unicode_characters
  before_validation :remove_invalid_published_at
  before_save :set_cached_entities
  before_save :set_all_dates

  before_save :calculate_base_scores
  before_save :fetch_video_duration
  before_save :set_caches
  before_save :detect_language
  before_create :create_password
  before_destroy :before_destroy_actions, prepend: true

  after_save :create_conditional_autovomits
  after_save :bust_cache
  after_save :collection_cleanup
  after_save :generate_social_image

  after_update_commit :update_notifications, if: proc { |article|
                                                   article.notifications.any? && !article.saved_changes.empty?
                                                 }
  after_update_commit :update_notification_subscriptions, if: proc { |article|
    article.saved_change_to_user_id?
  }

  after_commit :async_score_calc, :touch_collection, :enrich_image_attributes, :record_field_test_event,
               on: %i[create update]

  # The trigger `update_reading_list_document` is used to keep the `articles.reading_list_document` column updated.
  #
  # Its body is inserted in a PostgreSQL trigger function and that joins the columns values
  # needed to search documents in the context of a "reading list".
  #
  # Please refer to https://github.com/jenseng/hair_trigger#usage in case you want to change or update the trigger.
  #
  # Additional information on how triggers work can be found in
  # => https://www.postgresql.org/docs/11/trigger-definition.html
  # => https://www.cybertec-postgresql.com/en/postgresql-how-to-write-a-trigger/
  #
  # Adapted from https://dba.stackexchange.com/a/289361/226575
  trigger
    .name(:update_reading_list_document).before(:insert, :update).for_each(:row)
    .declare("l_org_vector tsvector; l_user_vector tsvector") do
    <<~SQL
      NEW.reading_list_document :=
        setweight(to_tsvector('simple'::regconfig, unaccent(coalesce(NEW.title, ''))), 'A') ||
        setweight(to_tsvector('simple'::regconfig, unaccent(coalesce(NEW.cached_tag_list, ''))), 'B') ||
        setweight(to_tsvector('simple'::regconfig, unaccent(coalesce(NEW.body_markdown, ''))), 'C') ||
        setweight(to_tsvector('simple'::regconfig, unaccent(coalesce(NEW.cached_user_name, ''))), 'D') ||
        setweight(to_tsvector('simple'::regconfig, unaccent(coalesce(NEW.cached_user_username, ''))), 'D') ||
        setweight(to_tsvector('simple'::regconfig,
          unaccent(
            coalesce(
              array_to_string(
                -- cached_organization is serialized to the DB as a YAML string, we extract only the name attribute
                regexp_match(NEW.cached_organization, 'name: (.*)$', 'n'),
                ' '
              ),
              ''
            )
          )
        ), 'D');
    SQL
  end

  # @todo Enforce the serialization class (e.g., Articles::CachedEntity)
  # @see https://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods/Serialization/ClassMethods.html#method-i-serialize
  serialize :cached_user

  # @todo Enforce the serialization class (e.g., Articles::CachedEntity)
  # @see https://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods/Serialization/ClassMethods.html#method-i-serialize
  serialize :cached_organization

  # TODO: [@rhymes] Rename the article column and the trigger name.
  # What was initially meant just for the reading list (filtered using the `reactions` table),
  # is also used for the article search page.
  # The name of the `tsvector` column and its related trigger should be adapted.
  pg_search_scope :search_articles,
                  against: :reading_list_document,
                  using: {
                    tsearch: {
                      prefix: true,
                      tsvector_column: :reading_list_document
                    }
                  },
                  ignoring: :accents

  # [@jgaskins] We use an index on `published`, but since it's a boolean value
  #   the Postgres query planner often skips it due to lack of diversity of the
  #   data in the column. However, since `published_at` is a *very* diverse
  #   column and can scope down the result set significantly, the query planner
  #   can make heavy use of it.
  scope :published, lambda {
    where(published: true)
      .where("published_at <= ?", Time.current)
  }
  scope :unpublished, -> { where(published: false) }

  scope :full_posts, -> { where(type_of: :full_post) }
  scope :statuses, -> { where(type_of: :status) }

  scope :not_authored_by, ->(user_id) { where.not(user_id: user_id) }

  # [@jeremyf] For approved articles is there always an assumption of
  #            published?  Regardless, the scope helps us deal with
  #            that in the future.
  scope :approved, -> { where(approved: true) }

  scope :from_subforem, lambda { |subforem_id = nil|
    subforem_id ||= RequestStore.store[:subforem_id]
    if subforem_id.present? && subforem_id == RequestStore.store[:root_subforem_id]
      # No additional conditions; just return the current scope
      where(nil)
    elsif [0, RequestStore.store[:default_subforem_id]].include?(subforem_id.to_i)
      where("articles.subforem_id IN (?) OR articles.subforem_id IS NULL", [nil, subforem_id, RequestStore.store[:default_subforem_id].to_i])
    else
      # where(subforem_id: subforem_id)
      where("articles.subforem_id = ?", subforem_id)
    end
  }

  scope :admin_published_with, lambda { |tag_name|
    published
      .where(user_id: User.with_role(:super_admin)
                          .union(User.with_role(:admin))
                          .union(id: [Settings::Community.staff_user_id,
                                      Settings::General.mascot_user_id].compact)
                          .select(:id)).order(published_at: :desc).tagged_with(tag_name)
  }

  scope :user_published_with, lambda { |user_id, tag_name|
    published
      .where(user_id: user_id)
      .order(published_at: :desc)
      .tagged_with(tag_name)
  }

  scope :active_help, lambda {
    stories = published.cached_tagged_with("help").order(created_at: :desc)

    stories.where(published_at: 12.hours.ago.., comments_count: ..5, score: -3..).presence || stories
  }

  scope :limited_column_select, lambda {
    select(:path, :title, :id, :published,
           :comments_count, :public_reactions_count, :cached_tag_list,
           :main_image, :main_image_background_hex_color, :updated_at, :slug,
           :video, :user_id, :organization_id, :video_source_url, :video_code,
           :video_thumbnail_url, :video_closed_caption_track_url,
           :experience_level_rating, :experience_level_rating_distribution, :cached_user, :cached_organization,
           :published_at, :crossposted_at, :description, :reading_time, :video_duration_in_seconds, :score,
           :last_comment_at, :main_image_height, :type_of, :edited_at, :processed_html, :subforem_id)
  }

  scope :limited_columns_internal_select, lambda {
    select(:path, :title, :id, :featured, :approved, :published,
           :comments_count, :public_reactions_count, :cached_tag_list,
           :main_image, :main_image_background_hex_color, :updated_at, :max_score,
           :video, :user_id, :organization_id, :video_source_url, :video_code,
           :video_thumbnail_url, :video_closed_caption_track_url, :social_image,
           :published_from_feed, :crossposted_at, :published_at, :created_at, :edited_at,
           :body_markdown, :email_digest_eligible, :processed_html, :co_author_ids, :score, :type_of)
  }

  scope :sorting, lambda { |value|
    value ||= "creation-desc"
    kind, dir = value.split("-")

    dir = "desc" unless %w[asc desc].include?(dir)

    case kind
    when "creation"
      order(created_at: dir)
    when "views"
      order(page_views_count: dir)
    when "reactions"
      order(public_reactions_count: dir)
    when "comments"
      order(comments_count: dir)
    when "published"
      # NOTE: For recently published, we further filter to only published posts
      order(published_at: dir).published
    else
      order(created_at: dir)
    end
  }

  # @note This includes the `featured` scope, which may or may not be
  #       something we expose going forward.  However, it was
  #       something used in two of the three queries we had that
  #       included the where `score > Settings::UserExperience.home_feed_minimum_score`
  scope :with_at_least_home_feed_minimum_score, lambda {
    featured.or(
      where(score: Settings::UserExperience.home_feed_minimum_score..),
    )
  }

  scope :featured, -> { where(featured: true) }

  scope :feed, lambda {
                 published.includes(:taggings)
                   .select(
                     :id, :published_at, :processed_html, :user_id, :organization_id, :title, :path, :cached_tag_list
                   )
               }

  scope :with_video, lambda {
                       published
                         .where.not(video: [nil, ""])
                         .where.not(video_thumbnail_url: [nil, ""])
                         .where("score > ?", -4)
                     }

  scope :eager_load_serialized_data, -> { includes(:user, :organization, :tags) }

  scope :above_average, lambda {
    order(:score).where("score >= ?", average_score)
  }

  def self.average_score
    Rails.cache.fetch("article_average_score", expires_in: 1.day) do
      unscoped { where(score: 0..).average(:score) } || 0.0
    end
  end

  def self.seo_boostable(tag = nil, time_ago = 18.days.ago)
    # Time ago sometimes returns this phrase instead of a date
    time_ago = 5.days.ago if time_ago == "latest"

    # Time ago sometimes is given as nil and should then be the default. I know, sloppy.
    time_ago = 75.days.ago if time_ago.nil?

    relation = Article.published.from_subforem
      .order(organic_page_views_past_month_count: :desc)
      .where("score > ?", 8)
      .where("published_at > ?", time_ago)
      .limit(20)

    fields = %i[path title comments_count created_at]
    if tag
      relation.cached_tagged_with(tag).pluck(*fields)
    else
      relation.pluck(*fields)
    end
  end

  def self.search_optimized(tag = nil)
    relation = Article.published.from_subforem
      .order(updated_at: :desc)
      .where.not(search_optimized_title_preamble: nil)
      .limit(20)

    fields = %i[path search_optimized_title_preamble comments_count created_at]
    if tag
      relation.cached_tagged_with(tag).pluck(*fields)
    else
      relation.pluck(*fields)
    end
  end

  def processed_html_final
    # This is a final non-database-driven step to adjust processed html
    # It is sort of a hack to avoid having to reprocess all articles
    # It is currently only for this one cloudflare domain change
    # It is duplicated across article, bullboard and comment where it is most needed
    # In the future this could be made more customizable. For now it's just this one thing.
    return processed_html if ApplicationConfig["PRIOR_CLOUDFLARE_IMAGES_DOMAIN"].blank? || ApplicationConfig["CLOUDFLARE_IMAGES_DOMAIN"].blank?

    processed_html.gsub(ApplicationConfig["PRIOR_CLOUDFLARE_IMAGES_DOMAIN"], ApplicationConfig["CLOUDFLARE_IMAGES_DOMAIN"])
  end

  def scheduled?
    published_at? && published_at.future?
  end

  def search_id
    "article_#{id}"
  end

  def processed_description
    if body_text.present?
      body_text
        .truncate(104, separator: " ")
        .tr("\n", " ")
        .strip
    else
      I18n.t("models.article.a_post_by", user_name: user.name)
    end
  end

  def body_text
    ActionView::Base.full_sanitizer.sanitize(processed_html)[0..7000]
  end

  def touch_by_reaction
    async_score_calc
  end

  def comments_blob
    return "" if comments_count.zero?

    ActionView::Base.full_sanitizer.sanitize(comments.pluck(:body_markdown).join(" "))[0..2200]
  end

  def url
    URL.article(self)
  end

  def username
    return organization.slug if organization

    user.username
  end

  def current_state_path
    published && !scheduled? ? "/#{username}/#{slug}" : "/#{username}/#{slug}?preview=#{password}"
  end

  def has_frontmatter?
    processed_content.has_front_matter?
  end

  def class_name
    self.class.name
  end

  def flare_tag
    @flare_tag ||= FlareTag.new(self).tag_hash
  end

  def edited?
    edited_at.present?
  end

  def readable_edit_date
    return unless edited?

    if edited_at.year == Time.current.year
      I18n.l(edited_at, format: :short)
    else
      I18n.l(edited_at, format: :short_with_yy)
    end
  end

  def readable_publish_date
    relevant_date = displayable_published_at
    return unless relevant_date

    if relevant_date.year == Time.current.year
      I18n.l(relevant_date, format: :short)
    elsif relevant_date
      I18n.l(relevant_date, format: :short_with_yy)
    end
  end

  def published_timestamp
    return "" unless published
    return "" unless crossposted_at || published_at

    displayable_published_at.utc.iso8601
  end

  def displayable_published_at
    crossposted_at.presence || published_at
  end

  def series
    # name of series article is part of
    collection&.slug
  end

  def all_series
    # all series names
    user&.collections&.pluck(:slug)
  end

  def cloudinary_video_url
    return if video_thumbnail_url.blank?

    Images::Optimizer.call(video_thumbnail_url, width: 880, quality: 80)
  end

  def video_duration_in_minutes
    duration = ActiveSupport::Duration.build(video_duration_in_seconds.to_i).parts

    # add default hours and minutes for the substitutions below
    duration = duration.reverse_merge(seconds: 0, minutes: 0, hours: 0)

    minutes_and_seconds = format("%<minutes>02d:%<seconds>02d", duration)
    return minutes_and_seconds if duration[:hours] < 1

    "#{duration[:hours]}:#{minutes_and_seconds}"
  end

  def update_score
    base_subscriber_adjustment = user.base_subscriber? ? Settings::UserExperience.index_minimum_score : 0
    spam_adjustment = user.spam? ? -500 : 0
    negative_reaction_adjustment = Reaction.where(reactable_id: user_id, reactable_type: "User").sum(:points)
    self.score = reactions.sum(:points) + spam_adjustment + negative_reaction_adjustment + base_subscriber_adjustment
    accepted_max = [max_score, user&.max_score.to_i].min
    accepted_max = [max_score, user&.max_score.to_i].max if accepted_max.zero?
    self.score = accepted_max if accepted_max.positive? && accepted_max < score

    update_columns(score: score,
                   privileged_users_reaction_points_sum: reactions.privileged_category.sum(:points),
                   comment_score: comments.sum(:score),
                   hotness_score: BlackBox.article_hotness_score(self))
  end

  def co_author_ids_list
    co_author_ids.join(", ")
  end

  def co_author_ids_list=(list_of_co_author_ids)
    self.co_author_ids = list_of_co_author_ids.split(",").map(&:strip)
  end

  def plain_html
    doc = Nokogiri::HTML.fragment(processed_html)
    doc.search(".highlight__panel").each(&:remove)
    doc.to_html
  end

  def followers
    # This will return an array, but the items will NOT be ActiveRecord objects.
    # The followers may also occasionally be nil because orphaned follows can possibly exist in the database.
    followers = user.followers_scoped.where(subscription_status: "all_articles").map(&:follower)

    if organization_id
      org_followers = organization.followers_scoped.where(subscription_status: "all_articles")
      followers += org_followers.map(&:follower)
    end

    followers.uniq.compact
  end

  def body_url?
    body_url.present?  # Returns true if body_url is not nil or an empty string
  end  

  def skip_indexing?
    # should the article be skipped indexed by crawlers?
    # true if unpublished, or spammy,
    # or low score, and not featured
    !published ||
      (score < Settings::UserExperience.index_minimum_score && !featured) ||
      published_at.to_i < Settings::UserExperience.index_minimum_date.to_i ||
      score < -1
  end

  def skip_indexing_reason
    return "unpublished" unless published
    return "negative_score" if score < -1
    return "below_minimum_score" if score < Settings::UserExperience.index_minimum_score && !featured
    return "below_minimum_date" if published_at.to_i < Settings::UserExperience.index_minimum_date.to_i

    "unknown"
  end

  def privileged_reaction_counts
    @privileged_reaction_counts ||= reactions.privileged_category.group(:category).count
  end

  def ordered_tag_adjustments
    tag_adjustments.includes(:user).order(:created_at).reverse
  end

  def async_score_calc
    return if !published? || destroyed?

    Articles::ScoreCalcWorker.perform_async(id)
  end

  def evaluate_and_update_column_from_markdown
    content_renderer = processed_content
    return unless content_renderer

    result = content_renderer.process_article
    self.update_column(:processed_html, result.processed_html)
  end
  
  def body_preview
    return unless type_of == "status"

    processed_html_final
  end

  private

  def set_markdown_from_body_url
    return unless body_url.present?

    self.body_markdown = "{% embed #{body_url} %}"
  end

  def collection_cleanup
    # Should only check to cleanup if Article was removed from collection
    return unless saved_change_to_collection_id? && collection_id.nil?

    collection = Collection.find(collection_id_before_last_save)
    return if collection.articles.count.positive?

    # Collection is empty
    collection.destroy
  end

  def detect_language
    return unless title_changed? || body_markdown_changed?

    self.language = Languages::Detection.call("#{title}. #{body_text}")
  end

  def search_score
    comments_score = (comments_count * 3).to_i
    partial_score = (comments_score + (public_reactions_count.to_i * 300 * user.reputation_modifier * score.to_i))
    calculated_score = hotness_score.to_i + partial_score
    calculated_score.to_i
  end

  def tag_keywords_for_search
    tags.pluck(:keywords_for_search).join
  end

  def calculated_path
    if organization
      "/#{organization.slug}/#{slug}"
    else
      "/#{username}/#{slug}"
    end
  end

  def set_caches
    return unless user

    self.cached_user_name = user_name
    self.cached_user_username = user_username
    self.path = calculated_path.downcase
  end

  def normalize_title
    return unless title

    self.title = title
      .gsub(TITLE_CHARACTERS_ALLOWED, " ")
      # Coalesce runs of whitespace into a single space character
      .gsub(/\s+/, " ")
      .strip
  end

  def processed_content
    return @processed_content if @processed_content && !body_markdown_changed?
    return unless user

    @processed_content = ContentRenderer.new(body_markdown, source: self, user: user)
  end

  def title_length_based_on_type_of
    max_length = case type_of
                 when "full_post"
                   128
                 when "status"
                   256
                 else
                   128 # Default length if type_of is nil or another value
                 end
    if title.blank?
      errors.add(:title, "can't be blank")
    elsif title.to_s.length > max_length
      errors.add(:title, "is too long (maximum is #{max_length} characters for #{type_of})")
    end
  end

  def replace_blank_title_for_status
    # Get content within H2 tags via regex
    self.title = "[Boost]" if title.blank? && type_of == "status"
  end

  def restrict_attributes_with_status_types
    # Return early if this is already saved and the body_markdown hasn't changed
    return if persisted? && !body_markdown_changed?

    # For now, there is no body allowed for status types
    if type_of == "status" && body_url.blank? && (body_markdown.present? || main_image.present? || collection_id.present?)
      errors.add(:body_markdown, "is not allowed for status types")
    end
  end

  def title_unique_for_user_past_five_minutes
    # Validates that the user did not create an article with the same title in the last five minutes
    return unless user_id && title
    return unless new_record?

    if Article.where(user_id: user_id, title: title).where("created_at > ?", 5.minutes.ago).exists?
      errors.add(:title, "has already been used in the last five minutes")
    end
  end


  def evaluate_markdown
    content_renderer = processed_content
    return unless content_renderer

    result = content_renderer.process_article

    self.processed_html = result.processed_html
    self.reading_time = result.reading_time

    front_matter = result.front_matter

    if front_matter.any?
      evaluate_front_matter(front_matter)
    elsif tag_list.any?
      set_tag_list(tag_list)
    end

    self.description = processed_description if description.blank?
  rescue ContentRenderer::ContentParsingError => e
    errors.add(:base, ErrorMessages::Clean.call(e.message))
  end

  def set_tag_list(tags)
    self.tag_list = [] # overwrite any existing tag with those from the front matter
    tag_list.add(tags, parse: true)
    self.tag_list = tag_list.map { |tag| Tag.find_preferred_alias_for(tag) }
  end

  def fetch_video_duration
    if video.present? && video_duration_in_seconds.zero?
      url = video_source_url.gsub(".m3u8", "1351620000001-200015_hls_v4.m3u8")
      duration = 0
      HTTParty.get(url).body.split("#EXTINF:").each do |chunk|
        duration += chunk.split(",")[0].to_f
      end
      self.video_duration_in_seconds = duration
      duration
    end
  rescue StandardError => e
    Rails.logger.error(e)
  end

  def update_notifications
    Notification.update_notifications(self, I18n.t("models.article.published"))
  end

  def update_notification_subscriptions
    NotificationSubscription.update_notification_subscriptions(self)
  end

  def before_destroy_actions
    bust_cache(destroying: true)
    article_ids = user.article_ids.dup
    if organization
      organization.touch(:last_article_at)
      article_ids.concat organization.article_ids
    end
    # perform busting cache in chunks in case there're a lot of articles
    # NOTE: `perform_bulk` takes an array of arrays as argument. Since the worker
    # takes an array of ids as argument, this becomes triple-nested.
    job_params = (article_ids.uniq.sort - [id]).each_slice(10).to_a.map { |ids| [ids] }
    Articles::BustMultipleCachesWorker.perform_bulk(job_params)
  end

  def evaluate_front_matter(hash)
    self.title = hash["title"] if hash["title"].present?
    set_tag_list(hash["tags"]) if hash["tags"].present?
    self.published = hash["published"] if %w[true false].include?(hash["published"].to_s)

    self.published_at = hash["published_at"] if hash["published_at"]
    self.published_at ||= parse_date(hash["date"]) if published

    set_main_image(hash)
    self.canonical_url = hash["canonical_url"] if hash["canonical_url"].present?

    update_description = hash["description"].present? || hash["title"].present?
    self.description = hash["description"] if update_description

    self.collection_id = nil if hash["title"].present?
    self.collection_id = Collection.find_series(hash["series"], user).id if hash["series"].present?
  end

  def set_main_image(hash)
    # At one point, we have set the main_image based on the front matter. Forever will that now dictate the behavior.
    if main_image_from_frontmatter?
      self.main_image = hash["cover_image"]
    elsif hash.key?("cover_image")
      # They've chosen the set cover image in the front matter, so we'll proceed with that assumption.
      self.main_image = hash["cover_image"]
      self.main_image_from_frontmatter = true
    end
  end

  def parse_date(date)
    # once published_at exist, it can not be adjusted
    published_at || date || Time.current
  end

  # When an article is saved, it ensures that the tags that were adjusted by moderators and admins
  # remain adjusted. We do not allow the author to add or remove tags that were previously added or
  # removed by moderators and admins.
  #
  # This method is called before validation, so that the tag_list can be validated.
  #
  # @return [String] an array of tag names.
  def validate_tag
    distinct_tag_adjustments = TagAdjustment.where(article_id: id, status: "committed")
      .select('DISTINCT ON ("tag_id") *')
      .order(:tag_id, updated_at: :desc, id: :desc)

    remove_tag_adjustments_from_tag_list(distinct_tag_adjustments)
    add_tag_adjustments_to_tag_list(distinct_tag_adjustments)

    # check there are not too many tags
    return errors.add(:tag_list, I18n.t("models.article.too_many_tags")) if tag_list.size > MAX_TAG_LIST_SIZE

    validate_tag_name(tag_list)
  end

  def remove_tag_adjustments_from_tag_list(distinct_adjustments)
    tags_to_remove = distinct_adjustments.select { |adj| adj.adjustment_type == "removal" }.pluck(:tag_name)
    tag_list.remove(tags_to_remove, parse: true) if tags_to_remove.present?
  end

  def add_tag_adjustments_to_tag_list(distinct_adjustments)
    tags_to_add = distinct_adjustments.select { |adj| adj.adjustment_type == "addition" }.pluck(:tag_name)
    return if tags_to_add.blank?

    tag_list.add(tags_to_add, parse: true)
    self.tag_list = tag_list.map { |tag| Tag.find_preferred_alias_for(tag) }
  end

  def validate_video
    if published && video_state == "PROGRESSING"
      return errors.add(:published,
                        I18n.t("models.article.video_processing"))
    end

    return unless video.present? && user.created_at > 2.weeks.ago

    errors.add(:video, I18n.t("models.article.video_unpermitted"))
  end

  def validate_collection_permission
    return unless collection && collection.user_id != user_id

    errors.add(:collection_id, I18n.t("models.article.series_unpermitted"))
  end

  def validate_co_authors
    return if co_author_ids.exclude?(user_id)

    errors.add(:co_author_ids, I18n.t("models.article.same_author"))
  end

  def validate_co_authors_must_not_be_the_same
    return if co_author_ids.uniq.count == co_author_ids.count

    errors.add(:base, I18n.t("models.article.unique_coauthor"))
  end

  def validate_co_authors_exist
    return if User.where(id: co_author_ids).count == co_author_ids.count

    errors.add(:co_author_ids, I18n.t("models.article.invalid_coauthor"))
  end

  def future_or_current_published_at
    # allow published_at in the future or within 15 minutes in the past
    return if !published || published_at.blank? || published_at > 15.minutes.ago

    errors.add(:published_at, I18n.t("models.article.future_or_current_published_at"))
  end

  def correct_published_at?
    return true unless changes["published_at"]

    # for drafts (that were never published before) or scheduled articles
    # => allow future or current dates, or no published_at
    if !published_at_was || published_at_was > Time.current
      # for articles published_from_feed (exported from rss) we allow past published_at
      if (published_at && published_at < 15.minutes.ago) && !published_from_feed
        errors.add(:published_at, I18n.t("models.article.future_or_current_published_at"))
      end
    else
      # for articles that have been published already (published or unpublished drafts) => immutable published_at
      # allow changes within one minute in case of editing via frontmatter w/o specifying seconds
      has_nils = changes["published_at"].include?(nil) # changes from nil or to nil
      close_enough = !has_nils && (published_at_was - published_at).between?(-60, 60)
      errors.add(:published_at, I18n.t("models.article.immutable_published_at")) if has_nils || !close_enough
    end
  end

  def canonical_url_must_not_have_spaces
    return unless canonical_url.to_s.match?(/[[:space:]]/)

    errors.add(:canonical_url, I18n.t("models.article.must_not_have_spaces"))
  end

  def user_mentions_in_markdown
    return if created_at.present? && created_at.before?(MAX_USER_MENTION_LIVE_AT)

    # The "mentioned-user" css is added by Html::Parser#user_link_if_exists
    mentions_count = Nokogiri::HTML(processed_html).css(".mentioned-user").size
    return if mentions_count <= Settings::RateLimit.mention_creation

    errors.add(:base,
               I18n.t("models.article.mention_too_many", count: Settings::RateLimit.mention_creation))
  end

  def create_slug
    if slug.blank? && title.present? && !published
      self.slug = title_to_slug + "-temp-slug-#{rand(10_000_000)}"
    elsif should_generate_final_slug?
      self.slug = title_to_slug
    end
  end

  def should_generate_final_slug?
    (title && published && slug.blank?) ||
      (title && published && slug.include?("-temp-slug-"))
  end

  def create_password
    return if password.present?

    self.password = SecureRandom.hex(60)
  end

  def set_cached_entities
    self.cached_organization = organization ? Articles::CachedEntity.from_object(organization) : nil
    self.cached_user = user ? Articles::CachedEntity.from_object(user) : nil
  end

  def set_all_dates
    set_crossposted_at
    set_last_comment_at
    set_nth_published_at
  end

  def set_published_date
    self.published_at = Time.current if published && published_at.blank?
  end

  def set_crossposted_at
    self.crossposted_at = Time.current if published && crossposted_at.blank? && published_from_feed
  end

  def set_last_comment_at
    return unless published_at.present? && last_comment_at == "Sun, 01 Jan 2017 05:00:00 UTC +00:00"

    self.last_comment_at = published_at
    user.touch(:last_article_at)
    organization&.touch(:last_article_at)
  end

  def set_nth_published_at
    return unless nth_published_by_author.zero? && published

    published_article_ids = user.articles.published.from_subforem.order(published_at: :asc).ids
    index = published_article_ids.index(id)

    self.nth_published_by_author = (index || published_article_ids.size) + 1
  end

  def title_to_slug
    truncated_title = title.size > 100 ? title[0..100].split[0...-1].join(" ") : title
    "#{Sterile.sluggerize(truncated_title)}-#{rand(100_000).to_s(26)}"
  end

  def touch_actor_latest_article_updated_at(destroying: false)
    return unless destroying || saved_changes.keys.intersection(%w[title cached_tag_list]).present?

    user.touch(:latest_article_updated_at)
    organization&.touch(:latest_article_updated_at)
  end

  def bust_cache(destroying: false)
    purge
    async_bust
    touch_actor_latest_article_updated_at(destroying: destroying)
  end

  def generate_social_image
    return if main_image.present?

    change = saved_change_to_attribute?(:title) || saved_change_to_attribute?(:published_at)
    return unless (change || social_image.blank?) && published

    Images::SocialImageWorker.perform_async(id, self.class.name)
  end

  def calculate_base_scores
    self.hotness_score = 1000 if hotness_score.blank?
  end

  def create_conditional_autovomits
    Spam::Handler.handle_article!(article: self)
  end

  def async_bust
    Articles::BustCacheWorker.perform_async(id)
  end

  def touch_collection
    collection.touch if collection && previous_changes.present?
  end

  def enrich_image_attributes
    return unless saved_change_to_attribute?(:processed_html) || saved_change_to_attribute?(:main_image)

    ::Articles::EnrichImageAttributesWorker.perform_async(id)
  end

  def remove_prohibited_unicode_characters
    return unless title&.match?(BIDI_CONTROL_CHARACTERS)

    bidi_stripped = title.gsub(BIDI_CONTROL_CHARACTERS, "")
    self.title = bidi_stripped if bidi_stripped.blank? # title only contains BIDI characters = blank title
  end

  # Sometimes published_at is set to a date *way way too far in the future*, likely a parsing mistake. Let's nullify.
  # Do this instead of invlidating the record, because we want to allow the user to fix the date and publish as needed.
  def remove_invalid_published_at
    return if published_at.blank?

    self.published_at = nil if published_at > 5.years.from_now
  end

  def record_field_test_event
    return unless published?
    return if FieldTest.config["experiments"].nil?

    Users::RecordFieldTestEventWorker
      .perform_async(user_id, AbExperiment::GoalConversionHandler::USER_PUBLISHES_POST_GOAL)
  end
end
