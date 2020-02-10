class Comment < ApplicationRecord
  has_ancestry
  resourcify
  include AlgoliaSearch
  include Reactable
  belongs_to :commentable, polymorphic: true
  counter_culture :commentable
  belongs_to :user
  counter_culture :user
  has_many :mentions, as: :mentionable, inverse_of: :mentionable, dependent: :destroy
  has_many :notifications, as: :notifiable, inverse_of: :notifiable, dependent: :delete_all
  has_many :notification_subscriptions, as: :notifiable, inverse_of: :notifiable, dependent: :destroy

  validates :body_markdown, presence: true, length: { in: 1..25_000 },
                            uniqueness: { scope: %i[user_id
                                                    ancestry
                                                    commentable_id
                                                    commentable_type] }
  validates :commentable_id, presence: true
  validates :commentable_type, inclusion: { in: %w[Article PodcastEpisode] }
  validates :user_id, presence: true

  after_create   :after_create_checks
  after_commit   :calculate_score
  after_update_commit :update_notifications, if: proc { |comment| comment.saved_changes.include? "body_markdown" }
  after_save     :bust_cache
  after_save     :synchronous_bust
  after_destroy  :after_destroy_actions
  before_destroy :before_destroy_actions
  after_create_commit :send_email_notification, if: :should_send_email_notification?
  after_create_commit :create_first_reaction
  after_create_commit :send_to_moderator
  before_save    :set_markdown_character_count, if: :body_markdown
  before_create  :adjust_comment_parent_based_on_depth
  after_update   :remove_notifications, if: :deleted
  after_update   :update_descendant_notifications, if: :deleted
  before_validation :evaluate_markdown, if: -> { body_markdown && commentable }
  validate :permissions, if: :commentable

  alias touch_by_reaction save

  algoliasearch per_environment: true, enqueue: :trigger_index do
    attribute :id
    add_index "ordered_comments",
              id: :index_id,
              per_environment: true,
              enqueue: :trigger_index do
      attributes :id, :user_id, :commentable_id, :commentable_type, :id_code_generated, :path,
                 :id_code, :readable_publish_date, :parent_id, :positive_reactions_count, :created_at
      attribute :body_html do
        HTML_Truncator.truncate(processed_html,
                                500, ellipsis: '<a class="comment-read-more" href="' + path + '">... Read Entire Comment</a>')
      end
      attribute :url do
        path
      end
      attribute :css do
        custom_css
      end
      attribute :tag_list do
        commentable.tag_list
      end
      attribute :root_path do
        root&.path
      end
      attribute :parent_path do
        parent&.path
      end
      attribute :heart_ids do
        reactions.where(category: "like").pluck(:user_id)
      end
      attribute :user do
        {
          username: user.username,
          name: user.name,
          id: user.id,
          profile_pic: ProfileImage.new(user).get(width: 90),
          profile_image_90: ProfileImage.new(user).get(width: 90),
          github_username: user.github_username,
          twitter_username: user.twitter_username
        }
      end
      attribute :commentable do
        {
          path: commentable&.path,
          title: commentable&.title,
          tag_list: commentable&.tag_list,
          id: commentable&.id
        }
      end
      tags do
        [commentable.tag_list,
         "user_#{user_id}",
         "commentable_#{commentable_type}_#{commentable_id}"].flatten.compact
      end
      ranking ["desc(created_at)"]
    end
  end

  def self.tree_for(commentable, limit = 0)
    commentable.comments.includes(:user).arrange(order: "score DESC").to_a[0..limit - 1].to_h
  end

  def self.trigger_index(record, remove)
    # record is removed from index synchronously in before_destroy_actions
    return if remove

    if record.deleted == false
      Search::IndexWorker.perform_async("Comment", record.id)
    else
      Search::RemoveFromIndexWorker.perform_async(Comment.algolia_index_name, record.index_id)
    end
  end

  # this should remain public because it's called by AlgoliaSearch::AlgoliaJob in .trigger_index
  def remove_algolia_index
    remove_from_index!
    Search::RemoveFromIndexWorker.new.perform("ordered_comments_#{Rails.env}", index_id)
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
    parent_or_root_article.class.name.downcase.
      gsub("article", "post").
      gsub("podcastepisode", "episode")
  end

  def id_code_generated
    # 26 is the conversion base
    # eg. 1000.to_s(26) would be "1cc"
    id.to_s(26)
  end

  def custom_css
    MarkdownParser.new(body_markdown).tags_used.map do |tag|
      Rails.application.assets["ltags/#{tag}.css"].to_s
    end.join
  end

  def title(length = 80)
    return "[deleted]" if deleted
    return "[hidden by post author]" if hidden_by_commentable_user

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

  # public because it's used in the algolia indexing methods
  def index_id
    "comments-#{id}"
  end

  private

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
    fixed_body_markdown = MarkdownFixer.fix_for_comment(body_markdown)
    parsed_markdown = MarkdownParser.new(fixed_body_markdown)
    self.processed_html = parsed_markdown.finalize(link_attributes: { rel: "nofollow" })
    wrap_timestamps_if_video_present!
    shorten_urls!
  end

  def adjust_comment_parent_based_on_depth
    self.parent_id = parent.descendant_ids.last if parent && (parent.depth > 1 && parent.has_children?)
  end

  def wrap_timestamps_if_video_present!
    return unless commentable_type != "PodcastEpisode" && commentable.video.present?

    self.processed_html = processed_html.gsub(/(([0-9]:)?)(([0-5][0-9]|[0-9])?):[0-5][0-9]/) { |string| "<a href='#{commentable.path}?t=#{string}'>#{string}</a>" }
  end

  def shorten_urls!
    doc = Nokogiri::HTML.parse(processed_html)
    doc.css("a").each do |anchor|
      unless anchor.to_s.include?("<img") || anchor.attr("class")&.include?("ltag")
        anchor.content = strip_url(anchor.content) unless anchor.to_s.include?("<img")
      end
    end
    self.processed_html = doc.to_html.html_safe
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
    root.touch
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
    remove_algolia_index
  end

  def bust_cache
    Comments::BustCacheWorker.perform_async(id)
  end

  def synchronous_bust
    commentable.touch(:last_comment_at) if commentable.respond_to?(:last_comment_at)
    user.touch(:last_comment_at)
    CacheBuster.bust(commentable.path.to_s) if commentable
    expire_root_fragment
  end

  def send_email_notification
    Comments::SendEmailNotificationWorker.perform_async(id)
  end

  def should_send_email_notification?
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

  def permissions
    errors.add(:commentable_id, "is not valid.") if commentable_type == "Article" && !commentable.published
  end
end
