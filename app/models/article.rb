class Article < ApplicationRecord
  include CloudinaryHelper
  include ActionView::Helpers
  include AlgoliaSearch
  include Storext.model

  acts_as_taggable_on :tags

  attr_accessor :publish_under_org

  belongs_to :user
  belongs_to :job_opportunity, optional: true
  counter_culture :user
  belongs_to :organization, optional: true
  belongs_to :collection, optional: true
  has_many :comments,       as: :commentable
  has_many :reactions,      as: :reactable, dependent: :destroy
  has_many  :notifications, as: :notifiable

  validates :slug, presence: { if: :published? }, format: /\A[0-9a-z-]*\z/,
                   uniqueness: { scope: :user_id }
  validates :title, presence: true,
                    length: { maximum: 128 }
  validates :user_id, presence: true
  validates :feed_source_url, uniqueness: { allow_blank: true }
  validates :canonical_url,
            url: { allow_blank: true, no_local: true, schemes: ["https", "http"] },
            uniqueness: { allow_blank: true }
  # validates :description, length: { in: 10..170, if: :published? }
  validates :body_markdown, uniqueness: { scope: :user_id }
  validate :validate_tag
  validate :validate_video
  validates :video_state, inclusion: { in: %w(PROGRESSING COMPLETED) }, allow_nil: true
  validates :cached_tag_list, length: { maximum: 86 }
  validates :main_image, url: { allow_blank: true, schemes: ["https", "http"] }
  validates :main_image_background_hex_color, format: /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/
  validates :video, url: { allow_blank: true, schemes: ["https", "http"] }
  validates :video_source_url, url: { allow_blank: true, schemes: ["https"] }
  validates :video_thumbnail_url, url: { allow_blank: true, schemes: ["https", "http"] }
  validates :video_closed_caption_track_url, url: { allow_blank: true, schemes: ["https"] }
  validates :video_source_url, url: { allow_blank: true, schemes: ["https"] }

  before_validation :evaluate_markdown
  before_validation :create_slug
  before_create     :create_password
  before_save       :set_all_dates
  before_save       :calculate_base_scores
  before_save       :set_caches
  after_save        :async_score_calc, if: :published
  after_save        :bust_cache
  after_save        :update_main_image_background_hex
  after_save        :detect_human_language
  # after_save        :send_to_moderator
  # turned off for now
  before_destroy    :before_destroy_actions

  serialize :ids_for_suggested_articles

  scope :active_help, -> {
                        where(published: true).
                          tagged_with("help").
                          order("created_at DESC").
                          where("published_at > ? AND comments_count < ?", 12.hours.ago, 6)
                      }

  scope :limited_column_select, -> {
    select(:path, :title, :id,
    :comments_count, :positive_reactions_count, :cached_tag_list,
    :main_image, :main_image_background_hex_color, :updated_at, :slug,
    :video, :user_id, :organization_id, :video_source_url, :video_code,
    :video_thumbnail_url, :video_closed_caption_track_url,
    :published_at, :crossposted_at, :boost_states, :description)
  }

  scope :limited_columns_internal_select, -> {
    select(:path, :title, :id, :featured, :approved, :published,
    :comments_count, :positive_reactions_count, :cached_tag_list,
    :main_image, :main_image_background_hex_color, :updated_at, :boost_states,
    :video, :user_id, :organization_id, :video_source_url, :video_code,
    :video_thumbnail_url, :video_closed_caption_track_url, :social_image,
    :published_from_feed, :crossposted_at, :published_at, :featured_number,
    :live_now, :last_buffered, :facebook_last_buffered, :created_at, :body_markdown,
    :email_digest_eligible)
  }

  scope :boosted_via_additional_articles, -> {
    where("boost_states ->> 'boosted_additional_articles' = 'true'")
  }

  scope :boosted_via_dev_digest_email, -> {
    where("boost_states ->> 'boosted_dev_digest_email' = 'true'")
  }

  algoliasearch per_environment: true, enqueue: :trigger_delayed_index do
    attribute :title
    add_index "searchables",
                  id: :index_id,
                  per_environment: true,
                  enqueue: :trigger_delayed_index do
      attributes :title, :tag_list, :main_image, :id,
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
      attributes :title, :path, :class_name, :comments_count,
        :tag_list, :positive_reactions_count, :id, :hotness_score,
        :readable_publish_date, :flare_tag
      attribute :published_at_int do
        published_at.to_i
      end
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
                stories.order("published_at DESC")
              elsif time_ago
                stories.order("comments_count DESC").
                  where("published_at > ?", time_ago)
              else
                stories.order("last_comment_at DESC").
                  where("published_at > ?", (tags.present? ? 5 : 2).days.ago)
              end

    stories = stories.tagged_with(tags)

    stories.pluck(:path, :title, :comments_count, :created_at)
  end

  def self.active_eli5(time_ago)
    stories = where(published: true).tagged_with("explainlikeimfive")

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
    if remove
      record.delay.remove_from_index! if record&.persisted?
    else
      record.index_or_remove_from_index_where_appropriate
    end
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
    score = hotness_score.to_i + ((comments_count * 3).to_i + positive_reactions_count.to_i * 300 * user.reputation_modifier)
    score.to_i
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
    return if body_markdown.blank?
    begin
      fixed_body_markdown = MarkdownFixer.fix_all(body_markdown)
      parsed = FrontMatterParser::Parser.new(:md).call(fixed_body_markdown)
      parsed_markdown = MarkdownParser.new(parsed.content)
      self.processed_html = parsed_markdown.finalize
      evaluate_front_matter(parsed.front_matter)
    rescue StandardError => e
      errors[:base] << ErrorMessageCleaner.new(e.message).clean
    end
  end

  def has_frontmatter?
    fixed_body_markdown = MarkdownFixer.fix_all(body_markdown)
    parsed = FrontMatterParser::Parser.new(:md).call(fixed_body_markdown)
    parsed.front_matter["title"]
  end

  def class_name
    self.class.name
  end

  def flare_tag
    FlareTag.new(self).tag_hash
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
    if relevant_date && relevant_date.year == Time.now.year
      relevant_date&.strftime("%b %e")
    else
      relevant_date&.strftime("%b %e '%y")
    end
  end

  def self.cached_find(id)
    Rails.cache.fetch("find-article-by-id-#{id}", expires_in: 5.hours) do
      find(id)
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
    update_column(:hotness_score, BlackBox.article_hotness_score(self))
    update_column(:spaminess_rating, BlackBox.calculate_spaminess(self))
    index! if tag_list.exclude?("hiring")
  end
  handle_asynchronously :async_score_calc

  private

  # def send_to_moderator
  #   ModerationService.new.send_moderation_notification(self) if published
  #   turned off for now
  # end

  def before_destroy_actions
    bust_cache
    remove_algolia_index
    reactions.destroy_all
    user.delay.resave_articles
    organization&.delay&.resave_articles
  end

  def evaluate_front_matter(front_matter)
    token_msg = body_text[0..80] + "..."
    self.title = front_matter["title"] if front_matter["title"].present?
    if front_matter["tags"].present?
      ActsAsTaggableOn::Taggable::Cache.included(Article)
      self.tag_list = []
      tag_list.add(front_matter["tags"], parser: ActsAsTaggableOn::TagParser)
    end
    self.published = front_matter["published"] if ["true", "false"].include?(front_matter["published"].to_s)
    self.published_at = parsed_date(front_matter["date"]) if published
    self.main_image = front_matter["cover_image"] if front_matter["cover_image"].present?
    self.canonical_url = front_matter["canonical_url"] if front_matter["canonical_url"].present?
    self.description = front_matter["description"] || token_msg
    if front_matter["automatically_renew"].present? && tag_list.include?("hiring")
      self.automatically_renew = front_matter["automatically_renew"]
    end
  end

  def parsed_date(date)
    today_date = Time.now.to_datetime
    return published_at || today_date unless date
    given_date = date.to_datetime
    error_msg = "must be entered in DD/MM/YYYY format with current or past date"
    return errors.add(:date_time, error_msg) if given_date > today_date
    given_date
  end

  def validate_tag
    return errors.add(:tag_list, "exceed the maximum of 4 tags") if tag_list.length > 4
    tag_list.each do |tag|
      if tag.length > 20
        errors.add(:tag, "\"#{tag}\" is too long (maximum is 20 characters)")
      end
    end
  end

  def validate_video
    if published && video_state == "PROGRESSING"
      return errors.add(:published, "cannot be set to true if video is still processing")
    end
    if video.present? && !user.has_role?(:video_permission)
      return errors.add(:video, "cannot be added member without permission")
    end
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
    if published && published_at.blank?
      self.published_at = Time.now
      user.delay.resave_articles # tack-on functionality HACK
      organization&.delay&.resave_articles # tack-on functionality HACK
    end
  end

  def set_featured_number
    self.featured_number = Time.now.to_i if featured_number.blank? && published
  end

  def set_crossposted_at
    self.crossposted_at = Time.now if published && crossposted_at.blank? && published_from_feed
  end

  def set_last_comment_at
    if published_at.present? && last_comment_at == "Sun, 01 Jan 2017 05:00:00 UTC +00:00"
      self.last_comment_at = published_at
    end
  end

  def title_to_slug
    title.to_s.downcase.tr(" ", "-").gsub(/[^\w-]/, "").tr("_", "") + "-" + rand(100000).to_s(26)
  end

  def bust_cache
    if Rails.env.production?
      cache_buster = CacheBuster.new
      cache_buster.bust(path)
      cache_buster.bust(path + "?i=i")
      cache_buster.bust(path + "?preview=" + password)
      async_bust
    end
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
