class Article < ApplicationRecord
  include CloudinaryHelper
  include ActionView::Helpers
  include AlgoliaSearch
  include Storext.model
  include Reactable

  acts_as_taggable_on :tags

  attr_accessor :publish_under_org
  attr_writer :series

  belongs_to :user
  belongs_to :job_opportunity, optional: true
  counter_culture :user
  belongs_to :organization, optional: true
  belongs_to :collection, optional: true
  has_many :comments, as: :commentable
  has_many :buffer_updates
  has_many :notifications, as: :notifiable
  has_many :rating_votes
  has_many :page_views

  validates :slug, presence: { if: :published? }, format: /\A[0-9a-z-]*\z/,
                   uniqueness: { scope: :user_id }
  validates :title, presence: true,
                    length: { maximum: 128 }
  validates :user_id, presence: true
  validates :feed_source_url, uniqueness: { allow_blank: true }
  validates :canonical_url,
            url: { allow_blank: true, no_local: true, schemes: %w[https http] },
            uniqueness: { allow_blank: true }
  # validates :description, length: { in: 10..170, if: :published? }
  validates :body_markdown, uniqueness: { scope: %i[user_id title] }
  validate :validate_tag
  validate :validate_video
  validate :validate_collection_permission
  validates :video_state, inclusion: { in: %w[PROGRESSING COMPLETED] }, allow_nil: true
  validates :cached_tag_list, length: { maximum: 86 }
  validates :main_image, url: { allow_blank: true, schemes: %w[https http] }
  validates :main_image_background_hex_color, format: /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/
  validates :video, url: { allow_blank: true, schemes: %w[https http] }
  validates :video_source_url, url: { allow_blank: true, schemes: ["https"] }
  validates :video_thumbnail_url, url: { allow_blank: true, schemes: %w[https http] }
  validates :video_closed_caption_track_url, url: { allow_blank: true, schemes: ["https"] }
  validates :video_source_url, url: { allow_blank: true, schemes: ["https"] }

  before_validation :evaluate_markdown
  before_validation :create_slug
  before_create     :create_password
  before_save       :set_all_dates
  before_save       :calculate_base_scores
  before_save       :set_caches
  before_save       :fetch_video_duration
  after_save        :async_score_calc, if: :published
  after_save        :bust_cache
  after_save        :update_main_image_background_hex
  after_save        :detect_human_language
  after_update      :update_notifications, if: proc { |article| article.notifications.length.positive? && !article.saved_changes.empty? }
  # after_save        :send_to_moderator
  # turned off for now
  before_destroy    :before_destroy_actions

  serialize :ids_for_suggested_articles

  scope :cached_tagged_with, ->(tag) { where("cached_tag_list ~* ?", "^#{tag},| #{tag},|, #{tag}$|^#{tag}$") }

  scope :active_help, lambda {
                        where(published: true).
                          cached_tagged_with("help").
                          order("created_at DESC").
                          where("published_at > ? AND comments_count < ?", 12.hours.ago, 6)
                      }

  scope :limited_column_select, lambda {
    select(:path, :title, :id,
    :comments_count, :positive_reactions_count, :cached_tag_list,
    :main_image, :main_image_background_hex_color, :updated_at, :slug,
    :video, :user_id, :organization_id, :video_source_url, :video_code,
    :video_thumbnail_url, :video_closed_caption_track_url,
    :experience_level_rating, :experience_level_rating_distribution,
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

  algoliasearch per_environment: true, auto_remove: false, enqueue: :trigger_delayed_index do
    attribute :title
    add_index "searchables",
                  id: :index_id,
                  per_environment: true,
                  enqueue: :trigger_delayed_index do
      attributes :title, :tag_list, :main_image, :id, :reading_time, :score,
                :featured, :published, :published_at, :featured_number,
                :comments_count, :reactions_count, :positive_reactions_count,
                :path, :class_name, :user_name, :user_username, :comments_blob,
                :body_text, :tag_keywords_for_search, :search_score, :readable_publish_date, :flare_tag
      attribute :user do
        { username: user.username,
          name: user.name,
          profile_image_90: ProfileImage.new(user).get(90) }
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
      attributesForFaceting [:class_name]
      customRanking ["desc(search_score)", "desc(hotness_score)"]
    end

    add_index "ordered_articles",
                  id: :index_id,
                  per_environment: true,
                  enqueue: :trigger_delayed_index do
      attributes :title, :path, :class_name, :comments_count, :reading_time,
        :tag_list, :positive_reactions_count, :id, :hotness_score, :score, :readable_publish_date, :flare_tag, :user_id,
        :organization_id, :cloudinary_video_url, :video_duration_in_minutes, :experience_level_rating, :experience_level_rating_distribution
      attribute :published_at_int do
        published_at.to_i
      end
      attribute :user do
        { username: user.username,
          name: user.name,
          profile_image_90: ProfileImage.new(user).get(90) }
      end
      attribute :organization do
        if organization
          { slug: organization.slug,
            name: organization.name,
            profile_image_90: ProfileImage.new(organization).get(90) }
        end
      end
      tags do
        [tag_list,
         "user_#{user_id}",
         "username_#{user&.username}",
         "lang_#{language || 'en'}",
         ("organization_#{organization_id}" if organization)].flatten.compact
      end
      ranking ["desc(hotness_score)"]
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

  def self.filter_excluded_tags(tag = nil)
    if tag == "hiring"
      tagged_with("hiring")
    elsif tag
      tagged_with(tag).
        tagged_with("hiring", exclude: true)
    else
      tagged_with("hiring", exclude: true)
    end
  end

  def self.active_threads(tags = ["discuss"], time_ago = nil, number = 10)
    stories = where(published: true).
      limit(number)
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

  def self.active_eli5(time_ago)
    stories = where(published: true).cached_tagged_with("explainlikeimfive")

    stories = if time_ago == "latest"
                stories.order("published_at DESC").limit(3)
              elsif time_ago
                stories.order("comments_count DESC").
                  where("published_at > ?", time_ago).
                  limit(6)
              else
                stories.order("last_comment_at DESC").
                  where("published_at > ?", 5.days.ago).
                  limit(3)
              end
    stories.pluck(:path, :title, :comments_count, :created_at)
  end

  def body_text
    ActionView::Base.full_sanitizer.sanitize(processed_html)[0..7000]
  end

  def index_id
    "articles-#{id}"
  end

  def self.trigger_delayed_index(record, remove)
    # on destroy an article is removed from index in a before_destroy callback #before_destroy_actions
    return if remove

    record.index_or_remove_from_index_where_appropriate
  end

  def index_or_remove_from_index_where_appropriate
    if published && tag_list.exclude?("hiring")
      delay.index!
    else
      delay.remove_from_index!
      index = Algolia::Index.new("searchables_#{Rails.env}")
      index.delay.delete_object("articles-#{id}")
      index = Algolia::Index.new("ordered_articles_#{Rails.env}")
      index.delay.delete_object("articles-#{id}")
    end
  end

  def remove_algolia_index
    remove_from_index!
    index = Algolia::Index.new("searchables_#{Rails.env}")
    index.delete_object("articles-#{id}")
    index = Algolia::Index.new("ordered_articles_#{Rails.env}")
    index.delete_object("articles-#{id}")
  end

  def touch_by_reaction
    async_score_calc
    index!
  end

  def comments_blob
    ActionView::Base.full_sanitizer.sanitize(comments.pluck(:body_markdown).join(" "))[0..2200]
  end

  def username
    return organization.slug if organization

    user.username
  end

  def user_name
    user.name
  end

  def user_username
    user.username
  end

  def current_state_path
    published ? "/#{username}/#{slug}" : "/#{username}/#{slug}?preview=#{password}"
  end

  def search_score
    calculated_score = hotness_score.to_i + ((comments_count * 3).to_i + positive_reactions_count.to_i * 300 * user.reputation_modifier * score.to_i)
    calculated_score.to_i
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
  rescue StandardError => e
    errors[:base] << ErrorMessageCleaner.new(e.message).clean
  end

  def has_frontmatter?
    fixed_body_markdown = MarkdownFixer.fix_all(body_markdown)
    begin
      parsed = FrontMatterParser::Parser.new(:md).call(fixed_body_markdown)
      parsed.front_matter["title"]
    rescue Psych::SyntaxError
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

  def update_main_image_background_hex
    return if main_image.blank? || main_image_background_hex_color != "#dddddd"

    update_column(:main_image_background_hex_color, ColorFromImage.new(main_image).main)
  end
  handle_asynchronously :update_main_image_background_hex

  def detect_human_language
    return if language.present?

    update_column(:language, LanguageDetector.new(self).detect)
  end
  handle_asynchronously :detect_human_language

  def tag_keywords_for_search
    tags.pluck(:keywords_for_search).join
  end

  def readable_publish_date
    relevant_date = crossposted_at.present? ? crossposted_at : published_at
    if relevant_date && relevant_date.year == Time.current.year
      relevant_date&.strftime("%b %e")
    else
      relevant_date&.strftime("%b %e '%y")
    end
  end

  def self.seo_boostable(tag = nil)
    keyword_paths = SearchKeyword.
      where("google_position > ? AND google_position < ? AND google_volume > ? AND google_difficulty < ?",
      3, 20, 1000, 40).pluck(:google_result_path)
    if tag
      Article.where(path: keyword_paths, published: true, featured: true).
        tagged_with(tag).
        pluck(:path, :title, :comments_count, :created_at)

    else
      Article.where(path: keyword_paths, published: true, featured: true).
        pluck(:path, :title, :comments_count, :created_at)
    end
  end

  def async_score_calc
    Articles::ScoreCalcJob.perform_later(id)
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
    minutes = (video_duration_in_seconds.to_i / 60) % 60
    seconds = video_duration_in_seconds.to_i % 60
    seconds = "0#{seconds}" if seconds.to_s.size == 1
    "#{minutes}:#{seconds}"
  end

  def fetch_video_duration
    if video.present? && video_duration_in_seconds.zero?
      url = video_source_url.gsub(".m3u8", "1351620000001-200015_hls_v4.m3u8")
      duration = 0
      HTTParty.get(url).body.split("#EXTINF:").each do |chunk|
        duration += chunk.split(",")[0].to_f
      end
      duration
      self.video_duration_in_seconds = duration
    end
  rescue StandardError => e
    puts e.message
  end

  private

  def update_notifications
    Notification.update_notifications(self, "Published")
  end

  # def send_to_moderator
  #   ModerationService.new.send_moderation_notification(self) if published
  #   turned off for now
  # end

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
      Articles::BustCacheJob.perform_later(ids)
    end
  end

  def evaluate_front_matter(front_matter)
    token_msg = body_text[0..80] + "..."
    self.title = front_matter["title"] if front_matter["title"].present?
    if front_matter["tags"].present?
      ActsAsTaggableOn::Taggable::Cache.included(Article)
      self.tag_list = []
      tag_list.add(front_matter["tags"], parser: ActsAsTaggableOn::TagParser)
      TagAdjustment.where(article_id: id, adjustment_type: "removal", status: "committed").pluck(:tag_name).each do |name|
        tag_list.remove(name, parser: ActsAsTaggableOn::TagParser)
      end
    end
    self.published = front_matter["published"] if %w[true false].include?(front_matter["published"].to_s)
    self.published_at = parsed_date(front_matter["date"]) if published
    self.main_image = front_matter["cover_image"] if front_matter["cover_image"].present?
    self.canonical_url = front_matter["canonical_url"] if front_matter["canonical_url"].present?
    self.description = front_matter["description"] || token_msg
    self.collection_id = nil if front_matter["title"].present?
    self.collection_id = Collection.find_series(front_matter["series"], user).id if front_matter["series"].present?
    self.automatically_renew = front_matter["automatically_renew"] if front_matter["automatically_renew"].present? && tag_list.include?("hiring")
  end

  def parsed_date(date)
    now = Time.current
    return published_at || now unless date

    error_msg = "must be entered in DD/MM/YYYY format with current or past date"
    return errors.add(:date_time, error_msg) if date > now

    date
  end

  def validate_tag
    # remove adjusted tags
    TagAdjustment.where(article_id: id, adjustment_type: "removal", status: "committed").pluck(:tag_name).each do |name|
      tag_list.remove(name, parser: ActsAsTaggableOn::TagParser)
      self.tag_list = tag_list
    end
    return errors.add(:tag_list, "exceed the maximum of 4 tags") if tag_list.length > 4

    tag_list.each do |tag|
      errors.add(:tag, "\"#{tag}\" is too long (maximum is 20 characters)") if tag.length > 20
    end
  end

  def validate_video
    return errors.add(:published, "cannot be set to true if video is still processing") if published && video_state == "PROGRESSING"
    return errors.add(:video, "cannot be added member without permission") if video.present? && user.created_at > 2.weeks.ago
  end

  def validate_collection_permission
    errors.add(:collection_id, "must be one you have permission to post to") if collection && collection.user_id != user_id
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
    return unless password.blank?

    self.password = SecureRandom.hex(60)
  end

  def set_all_dates
    set_published_date
    set_featured_number
    set_crossposted_at
    set_last_comment_at
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

  def title_to_slug
    title.to_s.downcase.tr(" ", "-").gsub(/[^\w-]/, "").tr("_", "") + "-" + rand(100_000).to_s(26)
  end

  def bust_cache
    return unless Rails.env.production?

    cache_buster = CacheBuster.new
    cache_buster.bust(path)
    cache_buster.bust(path + "?i=i")
    cache_buster.bust(path + "?preview=" + password)
    async_bust
  end

  def calculate_base_scores
    self.hotness_score = 1000 if hotness_score.blank?
    self.spaminess_rating = 0 if new_record?
  end

  def async_bust
    CacheBuster.new.bust_article(self)
    HTTParty.get GeneratedImage.new(self).social_image if published
  end
  handle_asynchronously :async_bust
end
