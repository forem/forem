class Article < ApplicationRecord
  include CloudinaryHelper
  include ActionView::Helpers
  include AlgoliaSearch
  include Storext.model
  include Reactable
  include Searchable

  SEARCH_SERIALIZER = Search::ArticleSerializer
  SEARCH_CLASS = Search::FeedContent
  REACTION_INDEXED_FIELDS = %w[body_markdown published tag_list title].freeze

  acts_as_taggable_on :tags
  resourcify

  attr_accessor :publish_under_org
  attr_writer :series

  delegate :name, to: :user, prefix: true
  delegate :username, to: :user, prefix: true

  belongs_to :user
  belongs_to :organization, optional: true
  # touch: true was removed because when an article is updated, the associated collection
  # is touched along with all its articles(including this one). This causes eventually a deadlock.
  belongs_to :collection, optional: true

  counter_culture :user
  counter_culture :organization

  has_many :comments, as: :commentable, inverse_of: :commentable
  has_many :profile_pins, as: :pinnable, inverse_of: :pinnable
  has_many :buffer_updates, dependent: :destroy
  has_many :notifications, as: :notifiable, inverse_of: :notifiable, dependent: :delete_all
  has_many :notification_subscriptions, as: :notifiable, inverse_of: :notifiable, dependent: :destroy
  has_many :rating_votes
  has_many :page_views

  validates :slug, presence: { if: :published? }, format: /\A[0-9a-z\-_]*\z/,
                   uniqueness: { scope: :user_id }
  validates :title, presence: true,
                    length: { maximum: 128 }
  validates :user_id, presence: true
  validates :feed_source_url, uniqueness: { allow_blank: true }
  validates :canonical_url,
            url: { allow_blank: true, no_local: true, schemes: %w[https http] },
            uniqueness: { allow_blank: true }
  validates :body_markdown, length: { minimum: 0, allow_nil: false }, uniqueness: { scope: %i[user_id title] }
  validate :validate_tag
  validate :validate_video
  validate :validate_collection_permission
  validate :validate_liquid_tag_permissions
  validate :past_or_present_date
  validate :canonical_url_must_not_have_spaces
  validates :video_state, inclusion: { in: %w[PROGRESSING COMPLETED] }, allow_nil: true
  validates :cached_tag_list, length: { maximum: 126 }
  validates :main_image, url: { allow_blank: true, schemes: %w[https http] }
  validates :main_image_background_hex_color, format: /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/
  validates :video, url: { allow_blank: true, schemes: %w[https http] }
  validates :video_source_url, url: { allow_blank: true, schemes: ["https"] }
  validates :video_thumbnail_url, url: { allow_blank: true, schemes: %w[https http] }
  validates :video_closed_caption_track_url, url: { allow_blank: true, schemes: ["https"] }
  validates :video_source_url, url: { allow_blank: true, schemes: ["https"] }

  before_validation :evaluate_markdown, :create_slug
  before_create :create_password
  before_save :set_all_dates
  before_save :calculate_base_scores
  before_save :set_caches
  before_save :fetch_video_duration
  before_save :clean_data
  before_save :update_cached_user

  after_save :bust_cache, :detect_human_language
  after_save :notify_slack_channel_about_publication

  after_update_commit :update_notifications, if: proc { |article| article.notifications.any? && !article.saved_changes.empty? }
  after_update_commit :update_reading_list_reactions, if: proc { |article|
    REACTION_INDEXED_FIELDS.any? { |field| article.saved_changes[field] } && reactions.readinglist.any?
  }
  after_commit :async_score_calc, :update_main_image_background_hex, :touch_collection
  after_commit :index_to_elasticsearch, on: %i[create update]
  after_commit :remove_from_elasticsearch, on: [:destroy]

  before_destroy :before_destroy_actions, prepend: true

  serialize :cached_user
  serialize :cached_organization

  scope :published, -> { where(published: true) }
  scope :unpublished, -> { where(published: false) }

  scope :admin_published_with, lambda { |tag_name|
    published.
      where(user_id: SiteConfig.staff_user_id).
      order(published_at: :desc).
      tagged_with(tag_name)
  }

  scope :user_published_with, lambda { |user_id, tag_name|
    published.
      where(user_id: user_id).
      order(published_at: :desc).
      tagged_with(tag_name)
  }

  scope :cached_tagged_with, ->(tag) { where("cached_tag_list ~* ?", "^#{tag},| #{tag},|, #{tag}$|^#{tag}$") }

  scope :cached_tagged_by_approval_with, ->(tag) { cached_tagged_with(tag).where(approved: true) }

  scope :active_help, lambda {
    published.
      cached_tagged_with("help").
      order(created_at: :desc).
      where("published_at > ? AND comments_count < ? AND score > ?", 12.hours.ago, 6, -4)
  }

  scope :limited_column_select, lambda {
    select(:path, :title, :id, :published,
           :comments_count, :positive_reactions_count, :cached_tag_list,
           :main_image, :main_image_background_hex_color, :updated_at, :slug,
           :video, :user_id, :organization_id, :video_source_url, :video_code,
           :video_thumbnail_url, :video_closed_caption_track_url, :language,
           :experience_level_rating, :experience_level_rating_distribution, :cached_user, :cached_organization,
           :published_at, :crossposted_at, :boost_states, :description, :reading_time, :video_duration_in_seconds)
  }

  scope :limited_columns_internal_select, lambda {
    select(:path, :title, :id, :featured, :approved, :published,
           :comments_count, :positive_reactions_count, :cached_tag_list,
           :main_image, :main_image_background_hex_color, :updated_at, :boost_states,
           :video, :user_id, :organization_id, :video_source_url, :video_code,
           :video_thumbnail_url, :video_closed_caption_track_url, :social_image,
           :published_from_feed, :crossposted_at, :published_at, :featured_number,
           :live_now, :last_buffered, :facebook_last_buffered, :created_at, :body_markdown,
           :email_digest_eligible, :processed_html)
  }

  scope :boosted_via_additional_articles, lambda {
    where("boost_states ->> 'boosted_additional_articles' = 'true'")
  }

  scope :boosted_via_dev_digest_email, lambda {
    where("boost_states ->> 'boosted_dev_digest_email' = 'true'")
  }

  scope :sorting, lambda { |value|
    value ||= "creation-desc"
    kind, dir = value.split("-")

    dir = "desc" unless %w[asc desc].include?(dir)

    column =
      case kind
      when "creation"  then :created_at
      when "views"     then :page_views_count
      when "reactions" then :positive_reactions_count
      when "comments"  then :comments_count
      when "published" then :published_at
      else
        :created_at
      end

    order(column => dir.to_sym)
  }

  scope :feed, -> { published.select(:id, :published_at, :processed_html, :user_id, :organization_id, :title, :path) }

  scope :with_video, -> { published.where.not(video: [nil, ""], video_thumbnail_url: [nil, ""]).where("score > ?", -4) }

  algoliasearch per_environment: true, auto_remove: false, enqueue: :trigger_index do
    attribute :title
    add_index "searchables", id: :index_id, per_environment: true, enqueue: :trigger_index do
      attributes :title, :tag_list, :main_image, :id, :reading_time, :score,
                 :featured, :published, :published_at, :featured_number,
                 :comments_count, :reactions_count, :positive_reactions_count,
                 :path, :class_name, :user_name, :user_username, :comments_blob,
                 :body_text, :tag_keywords_for_search, :search_score, :readable_publish_date, :flare_tag, :approved
      attribute :user do
        { username: user.username, name: user.name,
          profile_image_90: ProfileImage.new(user).get(width: 90), pro: user.pro? }
      end
      tags do
        [tag_list,
         "user_#{user_id}",
         "username_#{user&.username}",
         "lang_#{language || 'en'}",
         ("organization_#{organization_id}" if organization)].flatten.compact
      end
      searchableAttributes ["unordered(title)",
                            "body_text",
                            "tag_list",
                            "tag_keywords_for_search",
                            "user_name",
                            "user_username",
                            "comments_blob"]
      attributesForFaceting %i[class_name approved]
      customRanking ["desc(search_score)", "desc(hotness_score)"]
    end

    add_index "ordered_articles", id: :index_id, per_environment: true, enqueue: :trigger_index do
      attributes :title, :path, :class_name, :comments_count, :reading_time, :language,
                 :tag_list, :positive_reactions_count, :id, :hotness_score, :score, :readable_publish_date, :flare_tag, :user_id,
                 :organization_id, :cloudinary_video_url, :video_duration_in_minutes, :experience_level_rating, :experience_level_rating_distribution, :approved
      attribute :published_at_int do
        published_at.to_i
      end
      attribute :user do
        { username: user.username,
          name: user.name,
          profile_image_90: ProfileImage.new(user).get(width: 90) }
      end
      attribute :organization do
        if organization
          { slug: organization.slug,
            name: organization.name,
            profile_image_90: ProfileImage.new(organization).get(width: 90) }
        end
      end
      tags do
        [tag_list, "user_#{user_id}", "username_#{user&.username}", "lang_#{language || 'en'}",
         ("organization_#{organization_id}" if organization)].flatten.compact
      end
      ranking ["desc(hotness_score)"]
      attributesForFaceting %i[class_name approved]
      add_replica "ordered_articles_by_positive_reactions_count", inherit: true, per_environment: true do
        ranking ["desc(positive_reactions_count)"]
      end
      add_replica "ordered_articles_by_published_at", inherit: true, per_environment: true do
        ranking ["desc(published_at_int)"]
      end
    end
  end

  store_attributes :boost_states do
    boosted_additional_articles Boolean, default: false
    boosted_dev_digest_email Boolean, default: false
    boosted_additional_tags String, default: ""
  end

  def self.active_threads(tags = ["discuss"], time_ago = nil, number = 10)
    stories = published.limit(number)
    stories = if time_ago == "latest"
                stories.order("published_at DESC").where("score > ?", -5)
              elsif time_ago
                stories.order("comments_count DESC").
                  where("published_at > ? AND score > ?", time_ago, -5)
              else
                stories.order("last_comment_at DESC").
                  where("published_at > ? AND score > ?", (tags.present? ? 5 : 2).days.ago, -5)
              end
    stories = tags.size == 1 ? stories.cached_tagged_with(tags.first) : stories.tagged_with(tags)
    stories.pluck(:path, :title, :comments_count, :created_at)
  end

  def self.seo_boostable(tag = nil, time_ago = 18.days.ago)
    time_ago = 5.days.ago if time_ago == "latest" # Time ago sometimes returns this phrase instead of a date
    time_ago = 75.days.ago if time_ago.nil? # Time ago sometimes is given as nil and should then be the default. I know, sloppy.

    relation = Article.published.
      order(organic_page_views_past_month_count: :desc).
      where("score > ?", 8).
      where("published_at > ?", time_ago).
      limit(25)

    fields = %i[path title comments_count created_at]
    if tag
      relation.cached_tagged_with(tag).pluck(*fields)
    else
      relation.pluck(*fields)
    end
  end

  def self.trigger_index(record, remove)
    # on destroy an article is removed from index in a before_destroy callback #before_destroy_actions
    return if remove

    if record.published && record.tag_list.exclude?("hiring")
      Search::IndexWorker.perform_async("Article", record.id)
    else
      Search::RemoveFromIndexWorker.perform_async(Article.algolia_index_name, record.id)
      Search::RemoveFromIndexWorker.perform_async("searchables_#{Rails.env}", record.index_id)
      Search::RemoveFromIndexWorker.perform_async("ordered_articles_#{Rails.env}", record.index_id)
    end
  end

  def search_id
    "article_#{id}"
  end

  def update_reading_list_reactions
    if published
      reactions.readinglist.find_each(&:index_to_elasticsearch)
    elsif saved_changes["published"]
      reactions.readinglist.find_each(&:remove_from_elasticsearch)
    end
  end

  def processed_description
    text_portion = body_text.present? ? body_text[0..100].tr("\n", " ").strip.to_s : ""
    text_portion = text_portion.strip + "..." if body_text.size > 100
    return "A post by #{user.name}" if text_portion.blank?

    text_portion.strip
  end

  def body_text
    ActionView::Base.full_sanitizer.sanitize(processed_html)[0..7000]
  end

  def remove_algolia_index
    remove_from_index!
    delete_related_objects
  end

  def touch_by_reaction
    async_score_calc
    index!
    index_to_elasticsearch
  end

  def comments_blob
    return "" if comments_count.zero?

    ActionView::Base.full_sanitizer.sanitize(comments.pluck(:body_markdown).join(" "))[0..2200]
  end

  def username
    return organization.slug if organization

    user.username
  end

  def current_state_path
    published ? "/#{username}/#{slug}" : "/#{username}/#{slug}?preview=#{password}"
  end

  def has_frontmatter?
    fixed_body_markdown = MarkdownFixer.fix_all(body_markdown)
    begin
      parsed = FrontMatterParser::Parser.new(:md).call(fixed_body_markdown)
      parsed.front_matter["title"].present?
    rescue Psych::SyntaxError, Psych::DisallowedClass
      # if frontmatter is invalid, still render editor with errors instead of 500ing
      true
    end
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
      edited_at.strftime("%b %e")
    else
      edited_at.strftime("%b %e '%y")
    end
  end

  def readable_publish_date
    relevant_date = crossposted_at.presence || published_at
    if relevant_date && relevant_date.year == Time.current.year
      relevant_date&.strftime("%b %e")
    else
      relevant_date&.strftime("%b %e '%y")
    end
  end

  def published_timestamp
    return "" unless published
    return "" unless crossposted_at || published_at

    (crossposted_at || published_at).utc.iso8601
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

    ApplicationController.helpers.cloudinary(video_thumbnail_url, 880)
  end

  def video_duration_in_minutes
    minutes = video_duration_in_minutes_integer
    seconds = video_duration_in_seconds.to_i % 60
    seconds = "0#{seconds}" if seconds.to_s.size == 1

    hours = (video_duration_in_seconds.to_i / 3600)
    minutes = "0#{minutes}" if hours.positive? && minutes < 10
    hours < 1 ? "#{minutes}:#{seconds}" : "#{hours}:#{minutes}:#{seconds}"
  end

  def video_duration_in_minutes_integer
    (video_duration_in_seconds.to_i / 60) % 60
  end

  # keep public because it's used in algolia jobs
  def index_id
    "articles-#{id}"
  end

  def update_score
    new_score = reactions.sum(:points) + Reaction.where(reactable_id: user_id, reactable_type: "User").sum(:points)
    update_columns(score: new_score,
                   comment_score: comments.sum(:score),
                   hotness_score: BlackBox.article_hotness_score(self),
                   spaminess_rating: BlackBox.calculate_spaminess(self))
  end

  private

  def delete_related_objects
    Search::RemoveFromIndexWorker.new.perform("searchables_#{Rails.env}", index_id)
    Search::RemoveFromIndexWorker.new.perform("ordered_articles_#{Rails.env}", index_id)
  end

  def search_score
    calculated_score = hotness_score.to_i + ((comments_count * 3).to_i + positive_reactions_count.to_i * 300 * user.reputation_modifier * score.to_i)
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
    self.path = calculated_path
  end

  def evaluate_markdown
    fixed_body_markdown = MarkdownFixer.fix_all(body_markdown || "")
    parsed = FrontMatterParser::Parser.new(:md).call(fixed_body_markdown)
    parsed_markdown = MarkdownParser.new(parsed.content)
    self.reading_time = parsed_markdown.calculate_reading_time
    self.processed_html = parsed_markdown.finalize
    evaluate_front_matter(parsed.front_matter)
    self.description = processed_description if description.blank?
  rescue StandardError => e
    errors[:base] << ErrorMessageCleaner.new(e.message).clean
  end

  def update_main_image_background_hex
    return if main_image.blank? || main_image_background_hex_color != "#dddddd"

    Articles::UpdateMainImageBackgroundHexWorker.perform_async(id)
  end

  def detect_human_language
    return if language.present?

    update_column(:language, LanguageDetector.new(self).detect)
  end

  def async_score_calc
    return if !published? || destroyed?

    Articles::ScoreCalcWorker.perform_async(id)
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

  def liquid_tags_used
    MarkdownParser.new(body_markdown.to_s + comments_blob.to_s).tags_used
  rescue StandardError
    []
  end

  def update_notifications
    Notification.update_notifications(self, "Published")
  end

  def before_destroy_actions
    bust_cache
    remove_algolia_index
    article_ids = user.article_ids.dup
    if organization
      organization.touch(:last_article_at)
      article_ids.concat organization.article_ids
    end
    # perform busting cache in chunks in case there're a lot of articles
    (article_ids.uniq.sort - [id]).each_slice(10) do |ids|
      Articles::BustMultipleCachesWorker.perform_async(ids)
    end
  end

  def evaluate_front_matter(front_matter)
    self.title = front_matter["title"] if front_matter["title"].present?
    if front_matter["tags"].present?
      ActsAsTaggableOn::Taggable::Cache.included(Article)
      self.tag_list = [] # overwrite any existing tag with those from the front matter
      tag_list.add(front_matter["tags"], parser: ActsAsTaggableOn::TagParser)
      remove_tag_adjustments_from_tag_list
      add_tag_adjustments_to_tag_list
    end
    self.published = front_matter["published"] if %w[true false].include?(front_matter["published"].to_s)
    self.published_at = parse_date(front_matter["date"]) if published
    self.main_image = determine_image(front_matter)
    self.canonical_url = front_matter["canonical_url"] if front_matter["canonical_url"].present?
    self.description = front_matter["description"] if front_matter["description"].present? || front_matter["title"].present? # Do this if frontmatte exists at all
    self.collection_id = nil if front_matter["title"].present?
    self.collection_id = Collection.find_series(front_matter["series"], user).id if front_matter["series"].present?
  end

  def determine_image(front_matter)
    # In order to clear out the cover_image, we check for the key in the front_matter.
    # If the key exists, we use the value from it (a url or `nil`).
    # Otherwise, we fall back to the main_image on the article.
    has_cover_image = front_matter.include?("cover_image")

    if has_cover_image && (front_matter["cover_image"].present? || main_image)
      front_matter["cover_image"]
    else
      main_image
    end
  end

  def parse_date(date)
    # once published_at exist, it can not be adjusted
    published_at || date || Time.current
  end

  def validate_tag
    # remove adjusted tags
    remove_tag_adjustments_from_tag_list
    add_tag_adjustments_to_tag_list

    # check there are not too many tags
    return errors.add(:tag_list, "exceed the maximum of 4 tags") if tag_list.size > 4

    # check tags names aren't too long and don't contain non alphabet characters
    tag_list.each do |tag|
      new_tag = Tag.new(name: tag)
      new_tag.validate_name
      new_tag.errors.messages[:name].each { |message| errors.add(:tag, "\"#{tag}\" #{message}") }
    end
  end

  def remove_tag_adjustments_from_tag_list
    tags_to_remove = TagAdjustment.where(article_id: id, adjustment_type: "removal", status: "committed").pluck(:tag_name)
    tag_list.remove(tags_to_remove, parser: ActsAsTaggableOn::TagParser) if tags_to_remove.present?
  end

  def add_tag_adjustments_to_tag_list
    tags_to_add = TagAdjustment.where(article_id: id, adjustment_type: "addition", status: "committed").pluck(:tag_name)
    tag_list.add(tags_to_add, parser: ActsAsTaggableOn::TagParser) if tags_to_add.present?
  end

  def validate_video
    return errors.add(:published, "cannot be set to true if video is still processing") if published && video_state == "PROGRESSING"
    return errors.add(:video, "cannot be added by member without permission") if video.present? && user.created_at > 2.weeks.ago
  end

  def validate_collection_permission
    errors.add(:collection_id, "must be one you have permission to post to") if collection && collection.user_id != user_id
  end

  def past_or_present_date
    return unless published_at && published_at > Time.current

    errors.add(:date_time, "must be entered in DD/MM/YYYY format with current or past date")
  end

  def canonical_url_must_not_have_spaces
    errors.add(:canonical_url, "must not have spaces") if canonical_url.to_s.match?(/[[:space:]]/)
  end

  # Admin only beta tags etc.
  def validate_liquid_tag_permissions
    errors.add(:body_markdown, "must only use permitted tags") if liquid_tags_used.include?(PollTag) && !(user.has_role?(:super_admin) || user.has_role?(:admin))
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

  def update_cached_user
    if organization
      self.cached_organization = OpenStruct.new(set_cached_object(organization))
    end

    return unless user

    self.cached_user = OpenStruct.new(set_cached_object(user))
  end

  def set_cached_object(object)
    {
      name: object.name,
      username: object.username,
      slug: object == organization ? object.slug : object.username,
      profile_image_90: object.profile_image_90,
      profile_image_url: object.profile_image_url,
      pro: object == user ? user.pro? : false # organizations can't be pro users
    }
  end

  def set_all_dates
    set_published_date
    set_featured_number
    set_crossposted_at
    set_last_comment_at
    set_nth_published_at
  end

  def set_published_date
    self.published_at = Time.current if published && published_at.blank?
  end

  def set_featured_number
    self.featured_number = Time.current.to_i if featured_number.blank? && published
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
    published_article_ids = user.articles.published.order("published_at ASC").pluck(:id)
    index = published_article_ids.index(id)
    self.nth_published_by_author = (index || published_article_ids.size) + 1 if nth_published_by_author.zero? && published
  end

  def title_to_slug
    title.to_s.downcase.parameterize.tr("_", "") + "-" + rand(100_000).to_s(26)
  end

  def clean_data
    self.canonical_url = nil if canonical_url == ""
  end

  def bust_cache
    return unless Rails.env.production?

    CacheBuster.bust(path)
    CacheBuster.bust("#{path}?i=i")
    CacheBuster.bust("#{path}?preview=#{password}")
    async_bust
  end

  def calculate_base_scores
    self.hotness_score = 1000 if hotness_score.blank?
    self.spaminess_rating = 0 if new_record?
  end

  def async_bust
    Articles::BustCacheWorker.perform_async(id)
  end

  def touch_collection
    collection.touch if collection && previous_changes.present?
  end

  def notify_slack_channel_about_publication
    Slack::Messengers::ArticlePublished.call(article: self)
  end
end
