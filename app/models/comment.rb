class Comment < ApplicationRecord
  has_ancestry
  resourcify

  include Reactable
  include Searchable

  SEARCH_SERIALIZER = Search::CommentSerializer
  SEARCH_CLASS = Search::FeedContent

  BODY_MARKDOWN_SIZE_RANGE = (1..25_000).freeze
  COMMENTABLE_TYPES = %w[Article PodcastEpisode].freeze
  TITLE_DELETED = "[deleted]".freeze
  TITLE_HIDDEN = "[hidden by post author]".freeze

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

  validate :published_article, if: :commentable
  validates :body_markdown, presence: true, length: { in: BODY_MARKDOWN_SIZE_RANGE }
  validates :body_markdown, uniqueness: { scope: %i[user_id ancestry commentable_id commentable_type] }
  validates :commentable_id, presence: true, if: :commentable_type
  validates :commentable_type, inclusion: { in: COMMENTABLE_TYPES }, if: :commentable_id
  validates :positive_reactions_count, presence: true
  validates :public_reactions_count, presence: true
  validates :reactions_count, presence: true
  validates :user_id, presence: true

  after_create_commit :record_field_test_event
  after_create_commit :send_email_notification, if: :should_send_email_notification?
  after_create_commit :create_first_reaction
  after_create_commit :send_to_moderator

  after_commit :calculate_score, on: %i[create update]
  after_commit :index_to_elasticsearch, on: %i[create update]

  after_update_commit :update_notifications, if: proc { |comment| comment.saved_changes.include? "body_markdown" }

  after_commit :remove_from_elasticsearch, on: [:destroy]

  scope :eager_load_serialized_data, -> { includes(:user, :commentable) }

  alias touch_by_reaction save

  def self.tree_for(commentable, limit = 0)
    commentable.comments.includes(:user).arrange(order: "score DESC").to_a[0..limit - 1].to_h
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
    return TITLE_DELETED if deleted
    return TITLE_HIDDEN if hidden_by_commentable_user

    text = ActionController::Base.helpers.strip_tags(processed_html).strip
    truncated_text = ActionController::Base.helpers.truncate(text, length: length).gsub("&#39;", "'").gsub("&amp;", "&")
    HTMLEntities.new.decode(truncated_text)
  end

  def video
    nil
  end

  def readable_publish_date
    if created_at.year == Time.current.year
      created_at.strftime("%b %e")
    else
      created_at.strftime("%b %e '%y")
    end
  end

  def remove_notifications
    Notification.remove_all_without_delay(notifiable_ids: id, notifiable_type: "Comment")
  end

  def safe_processed_html
    processed_html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def root_exists?
    ancestry && Comment.exists?(id: ancestry)
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
    fixed_body_markdown = MarkdownProcessor::Fixer::FixForComment.call(body_markdown)
    parsed_markdown = MarkdownProcessor::Parser.new(fixed_body_markdown, source: self, user: user)
    self.processed_html = parsed_markdown.finalize(link_attributes: { rel: "nofollow" })
    wrap_timestamps_if_video_present! if commentable
    shorten_urls!
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
      unless anchor.to_s.include?("<img") || anchor.attr("class")&.include?("ltag")
        anchor.content = strip_url(anchor.content) unless anchor.to_s.include?("<img") # rubocop:disable Style/SoleNestedConditional
      end
    end
    self.processed_html = doc.to_html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def calculate_score
    Comments::CalculateScoreWorker.perform_async(id)
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

  def create_first_reaction
    Comments::CreateFirstReactionWorker.perform_async(id, user_id)
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
    return unless
      SiteConfig.spam_trigger_terms.any? { |term| Regexp.new(term.downcase).match?(title.downcase) }

    self.score = -1 # ensure notification is not sent if possibly spammy
  end

  def create_conditional_autovomits
    return unless
      SiteConfig.spam_trigger_terms.any? { |term| Regexp.new(term.downcase).match?(title.downcase) } &&
        user.registered_at > 5.days.ago

    Reaction.create(
      user_id: SiteConfig.mascot_user_id,
      reactable_id: id,
      reactable_type: "Comment",
      category: "vomit",
    )

    return unless Reaction.comment_vomits.where(reactable_id: user.comments.pluck(:id)).size > 2

    user.add_role(:banned)
    Note.create(
      author_id: SiteConfig.mascot_user_id,
      noteable_id: user_id,
      noteable_type: "User",
      reason: "automatic_suspend",
      content: "User suspended for too many spammy articles, triggered by autovomit.",
    )
  end

  def should_send_email_notification?
    parent_exists? &&
      parent_user.class.name != "Podcast" &&
      parent_user != user &&
      parent_user.email_comment_notifications &&
      parent_user.email &&
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

  def published_article
    errors.add(:commentable_id, "is not valid.") if commentable_type == "Article" && !commentable.published
  end

  def record_field_test_event
    return if FieldTest.config["experiments"].nil?

    Users::RecordFieldTestEventWorker
      .perform_async(user_id, "user_creates_comment")
  end

  def notify_slack_channel_about_warned_users
    Slack::Messengers::CommentUserWarned.call(comment: self)
  end

  def parent_exists?
    parent_id && Comment.exists?(id: parent_id)
  end
end
