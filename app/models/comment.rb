class Comment < ApplicationRecord
  has_ancestry
  resourcify

  include PgSearch::Model
  include Reactable
  include AlgoliaSearchable

  BODY_MARKDOWN_SIZE_RANGE = (1..25_000)

  COMMENTABLE_TYPES = %w[Article PodcastEpisode].freeze

  LOW_QUALITY_THRESHOLD = -75
  HIDE_THRESHOLD = -400 # hide comments below this threshold

  VALID_SORT_OPTIONS = %w[top latest oldest].freeze

  URI_REGEXP = %r{
    \A
    (?:https?://)?  # optional scheme
    .+?             # host
    (?::\d+)?       # optional port
    \z
  }x

  # The date that we began limiting the number of user mentions in a comment.
  MAX_USER_MENTION_LIVE_AT = Time.utc(2021, 3, 12).freeze

  belongs_to :commentable, polymorphic: true, optional: true
  belongs_to :user

  counter_culture :commentable
  counter_culture :user

  has_many :mentions, as: :mentionable, inverse_of: :mentionable, dependent: :destroy
  has_many :notifications, as: :notifiable, inverse_of: :notifiable, dependent: :delete_all
  has_many :notification_subscriptions, as: :notifiable, inverse_of: :notifiable, dependent: :destroy
  before_validation :evaluate_markdown, if: -> { body_markdown }
  before_save :set_markdown_character_count, if: :body_markdown
  before_save :synchronous_spam_score_check
  before_create :adjust_comment_parent_based_on_depth
  after_create :after_create_checks
  after_create :notify_slack_channel_about_warned_users
  after_update :update_descendant_notifications, if: :deleted
  after_update :remove_notifications, if: :remove_notifications?
  before_destroy :before_destroy_actions
  after_destroy :after_destroy_actions

  after_save :create_conditional_autovomits
  after_save :synchronous_bust
  after_save :bust_cache

  validate :discussion_not_locked, if: :commentable, on: :create
  validate :published_article, if: :commentable
  validate :user_mentions_in_markdown
  validates :body_markdown, presence: true, length: { in: BODY_MARKDOWN_SIZE_RANGE }
  validates :body_markdown, uniqueness: { scope: %i[user_id ancestry commentable_id commentable_type] }
  validates :commentable_id, presence: true, if: :commentable_type
  validates :commentable_type, inclusion: { in: COMMENTABLE_TYPES }, if: :commentable_id
  validates :positive_reactions_count, presence: true
  validates :public_reactions_count, presence: true
  validates :reactions_count, presence: true
  validates :commentable, on: :create, presence: {
    message: lambda do |object, _data|
      I18n.t("models.comment.has_been_deleted",
             type: I18n.t("models.comment.type.#{object.commentable_type.presence || 'item'}"))
    end
  }

  after_create_commit :record_field_test_event
  after_create_commit :send_email_notification, if: :should_send_email_notification?

  after_commit :calculate_score, on: %i[create update]

  after_update_commit :update_notifications, if: proc { |comment| comment.saved_changes.include? "body_markdown" }

  pg_search_scope :search_comments,
                  against: %i[body_markdown],
                  using: {
                    tsearch: {
                      prefix: true,
                      highlight: {
                        StartSel: "<mark>",
                        StopSel: "</mark>",
                        MaxFragments: 2
                      }
                    }
                  }

  scope :eager_load_serialized_data, -> { includes(:user, :commentable) }
  scope :good_quality, -> { where("score > ?", LOW_QUALITY_THRESHOLD) }

  alias touch_by_reaction save

  def self.title_deleted
    I18n.t("models.comment.deleted")
  end

  def self.title_hidden
    I18n.t("models.comment.hidden")
  end

  def self.title_image_only
    I18n.t("models.comment.image_only")
  end

  def self.build_comment(params, &blk)
    includes(user: :profile).new(params, &blk)
  end

  def search_id
    "comment_#{id}"
  end

  def path
    "/#{user.username}/comment/#{id_code_generated}"
  rescue StandardError
    "/404.html"
  end

  def parent_or_root_article
    parent || commentable
  end

  def parent_user
    parent_or_root_article.user
  end

  def parent_type
    parent_or_root_article.class.name.downcase
      .gsub("article", "post")
      .gsub("podcastepisode", "episode")
  end

  def id_code_generated
    # 26 is the conversion base
    # eg. 1000.to_s(26) would be "1cc"
    id.to_s(26)
  end

  def custom_css
    MarkdownProcessor::Parser.new(body_markdown).tags_used.map do |tag|
      Rails.application.assets["ltags/#{tag}.css"].to_s
    end.join
  end

  def title(length = 80)
    return self.class.title_deleted if deleted
    return self.class.title_hidden if hidden_by_commentable_user

    text = ActionController::Base.helpers.strip_tags(processed_html).strip
    return self.class.title_image_only if only_contains_image?(text)

    truncated_text = ActionController::Base.helpers.truncate(text, length: length).gsub("&#39;", "'").gsub("&amp;", "&")
    Nokogiri::HTML.fragment(truncated_text).text # unescapes all HTML entities
  end

  def video
    nil
  end

  def readable_publish_date
    if created_at.year == Time.current.year
      I18n.l(created_at, format: :short)
    else
      I18n.l(created_at, format: :short_with_yy)
    end
  end

  def remove_notifications
    Notification.remove_all_without_delay(notifiable_ids: id, notifiable_type: "Comment")
  end

  def safe_processed_html
    processed_html_final.html_safe # rubocop:disable Rails/OutputSafety
  end

  def root_exists?
    ancestry && Comment.exists?(id: ancestry)
  end

  def by_staff_account?
    user == User.staff_account
  end

  def privileged_reaction_counts
    @privileged_reaction_counts ||= reactions.privileged_category.group(:category).count
  end

  def calculate_score
    Comments::CalculateScoreWorker.perform_async(id)
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

  private

  def remove_notifications?
    deleted? || hidden_by_commentable_user?
  end

  def update_notifications
    Notification.update_notifications(self)
  end

  def update_descendant_notifications
    return unless has_children?

    Comment.where(id: descendant_ids).find_each do |comment|
      Notification.update_notifications(comment)
    end
  end

  def send_to_moderator
    return if user && user.comments_count > 2

    Notification.send_moderation_notification(self)
  end

  def evaluate_markdown
    return unless user

    renderer = ContentRenderer.new(body_markdown, source: self, user: user)
    self.processed_html = renderer.process(link_attributes: { rel: "nofollow" }).processed_html
    wrap_timestamps_if_video_present! if commentable
    shorten_urls!
  rescue ContentRenderer::ContentParsingError => e
    errors.add(:base, ErrorMessages::Clean.call(e.message))
  end

  def adjust_comment_parent_based_on_depth
    self.parent_id = parent.descendant_ids.last if parent_exists? && (parent.depth > 1 && parent.has_children?)
  end

  def wrap_timestamps_if_video_present!
    return unless commentable_type != "PodcastEpisode" && commentable.video.present?

    self.processed_html = processed_html.gsub(/(([0-9]:)?)(([0-5][0-9]|[0-9])?):[0-5][0-9]/) do |string|
      "<a href='#{commentable.path}?t=#{string}'>#{string}</a>"
    end
  end

  def shorten_urls!
    doc = Nokogiri::HTML.fragment(processed_html)
    doc.css("a").each do |anchor|
      next if anchor.inner_html.include?("<img")

      urls = anchor.content.scan(URI_REGEXP).flatten
      anchor_content = anchor.content
      urls.each do |url|
        anchor_content.sub!(/#{Regexp.escape(url)}/, strip_url(url))
      end
      anchor.inner_html = anchor.inner_html.sub(/#{Regexp.escape(anchor.content)}/, anchor_content)
    end
    self.processed_html = doc.to_html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def after_create_checks
    create_id_code
    touch_user
  end

  def create_id_code
    update_column(:id_code, id.to_s(26))
  end

  def touch_user
    user&.touch(:updated_at, :last_comment_at)
  end

  def expire_root_fragment
    if root_exists?
      root.touch
    else
      touch
    end
  end

  def after_destroy_actions
    Users::BustCacheWorker.perform_async(user_id)
    user.touch(:last_comment_at)
  end

  def before_destroy_actions
    commentable.touch(:last_comment_at) if commentable.respond_to?(:last_comment_at)
    ancestors.update_all(updated_at: Time.current)
    Comments::BustCacheWorker.new.perform(id)
  end

  def bust_cache
    Comments::BustCacheWorker.perform_async(id)
  end

  def synchronous_bust
    commentable.touch(:last_comment_at) if commentable.respond_to?(:last_comment_at)
    user.touch(:last_comment_at)
    EdgeCache::Bust.call(commentable.path.to_s) if commentable
    expire_root_fragment
  end

  def send_email_notification
    Comments::SendEmailNotificationWorker.perform_async(id)
  end

  def synchronous_spam_score_check
    self.score = -3 if user.registered_at > 48.hours.ago && body_markdown.include?("http")
    self.score = -5 if Settings::RateLimit.trigger_spam_for?(text: [title, body_markdown].join("\n"))
  end

  def create_conditional_autovomits
    Spam::Handler.handle_comment!(comment: self)
  end

  def should_send_email_notification?
    parent_exists? &&
      parent_user.class.name != "Podcast" &&
      parent_user != user &&
      parent_user.notification_setting.email_comment_notifications &&
      parent_user.email &&
      user&.badge_achievements_count&.positive? &&
      parent_or_root_article.receive_notifications
  end

  def strip_url(url)
    url.sub!(%r{https://}, "") if url.include?("https://")
    url.sub!(%r{http://}, "")  if url.include?("http://")
    url.sub!(/www./, "")       if url.include?("www.")
    url = url.truncate(37) unless url.include?(" ")
    url
  end

  def set_markdown_character_count
    # body_markdown is actually markdown, but that's a separate issue to be fixed soon
    self.markdown_character_count = body_markdown.size
  end

  def discussion_not_locked
    return unless commentable_type == "Article" && commentable.discussion_lock

    errors.add(:commentable_id, I18n.t("models.comment.locked"))
  end

  def published_article
    return unless commentable_type == "Article" && !commentable.published

    errors.add(:commentable_id, I18n.t("models.comment.published_article"))
  end

  def user_mentions_in_markdown
    return if created_at.present? && created_at.before?(MAX_USER_MENTION_LIVE_AT)

    # The "mentioned-user" css is added by Html::Parser#user_link_if_exists
    mentions_count = Nokogiri::HTML(processed_html).css(".mentioned-user").size
    return if mentions_count <= Settings::RateLimit.mention_creation

    errors.add(:base,
               I18n.t("models.comment.mention_too_many",
                      count: Settings::RateLimit.mention_creation))
  end

  def record_field_test_event
    return if FieldTest.config["experiments"].nil?

    Users::RecordFieldTestEventWorker
      .perform_async(user_id, AbExperiment::GoalConversionHandler::USER_CREATES_COMMENT_GOAL)
  end

  def notify_slack_channel_about_warned_users
    Slack::Messengers::CommentUserWarned.call(comment: self)
  end

  def parent_exists?
    parent_id && Comment.exists?(id: parent_id)
  end

  def only_contains_image?(stripped_text)
    # If stripped text is blank and processed html has <img> tags, then it's an image-only comment
    stripped_text.blank? && processed_html.include?("<img")
  end
end
