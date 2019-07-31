class Comment < ApplicationRecord
  has_ancestry
  include AlgoliaSearch
  include Reactable
  belongs_to :commentable, polymorphic: true
  counter_culture :commentable
  belongs_to :user
  counter_culture :user
  has_many :mentions, as: :mentionable, inverse_of: :mentionable, dependent: :destroy
  has_many :notifications, as: :notifiable, inverse_of: :notifiable, dependent: :destroy
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
  after_save     :calculate_score
  after_save     :bust_cache
  after_save     :synchronous_bust
  before_destroy :before_destroy_actions
  after_create   :send_email_notification, if: :should_send_email_notification?
  after_create   :create_first_reaction
  after_create   :send_to_moderator
  before_save    :set_markdown_character_count, if: :body_markdown
  before_create  :adjust_comment_parent_based_on_depth
  after_update   :update_notifications, if: proc { |comment| comment.saved_changes.include? "body_markdown" }
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
          profile_pic: ProfileImage.new(user).get(90),
          profile_image_90: ProfileImage.new(user).get(90),
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

  def self.trigger_index(record, remove)
    # record is removed from index synchronously in before_destroy_actions
    return if remove

    if record.deleted == false
      AlgoliaSearch::AlgoliaJob.perform_later(record, "index!")
    else
      AlgoliaSearch::AlgoliaJob.perform_later(record, "remove_algolia_index")
    end
  end

  def self.users_with_number_of_comments(user_ids, before_date)
    joins(:user).
      select("users.username, COUNT(comments.user_id) AS number_of_comments").
      where(user_id: user_ids).
      where(arel_table[:created_at].gt(before_date)).
      group(User.arel_table[:username]).
      order("number_of_comments DESC")
  end

  def remove_algolia_index
    remove_from_index!
    index = Algolia::Index.new("ordered_comments_#{Rails.env}")
    index.delete_object("comments-#{id}")
  end

  def index_id
    "comments-#{id}"
  end

  def self.rooted_on(commentable_id, commentable_type)
    includes(:user).
      select(:id, :user_id, :commentable_type, :commentable_id,
             :deleted, :created_at, :processed_html, :ancestry, :updated_at, :score).
      where(commentable_id: commentable_id, ancestry: nil, commentable_type: commentable_type)
  end

  def self.tree_for(commentable, limit = 0)
    commentable.comments.includes(:user).arrange(order: "score DESC").to_a[0..limit - 1].to_h
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
    id.to_s(26)
  end

  def custom_css
    MarkdownParser.new(body_markdown).tags_used.map do |tag|
      Rails.application.assets["ltags/#{tag}.css"].to_s
    end.join
  end

  def title(length = 80)
    return "[deleted]" if deleted

    text = ActionController::Base.helpers.strip_tags(processed_html).strip
    HTMLEntities.new.decode ActionController::Base.helpers.truncate(text, length: length).gsub("&#39;", "'").gsub("&amp;", "&")
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
    Notification.remove_all_without_delay(notifiable_id: id, notifiable_type: "Comment")
    Notification.remove_all_without_delay(notifiable_id: id, notifiable_type: "Comment", action: "Moderation")
    Notification.remove_all_without_delay(notifiable_id: id, notifiable_type: "Comment", action: "Reaction")
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
    return if user && user.comments_count > 10

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

    self.processed_html = processed_html.gsub(/(([0-9]:)?)(([0-5][0-9]|[0-9])?):[0-5][0-9]/) { |s| "<a href='#{commentable.path}?t=#{s}'>#{s}</a>" }
  end

  def shorten_urls!
    doc = Nokogiri::HTML.parse(processed_html)
    doc.css("a").each do |a|
      unless a.to_s.include?("<img") || a.attr("class")&.include?("ltag")
        a.content = strip_url(a.content) unless a.to_s.include?("<img")
      end
    end
    self.processed_html = doc.to_html.html_safe
  end

  def calculate_score
    Comments::CalculateScoreJob.perform_later(id)
  end

  def after_create_checks
    create_id_code
    touch_user
  end

  def create_id_code
    Comments::CreateIdCodeJob.perform_later(id)
  end

  def touch_user
    Comments::TouchUserJob.perform_later(id)
  end

  def expire_root_fragment
    root.touch
  end

  def create_first_reaction
    Comments::CreateFirstReactionJob.perform_later(id)
  end

  def before_destroy_actions
    commentable.touch(:last_comment_at) if commentable.respond_to?(:last_comment_at)
    ancestors.update_all(updated_at: Time.current)
    remove_notifications
    bust_cache_without_delay
    remove_algolia_index
  end

  def bust_cache_without_delay
    Comments::BustCacheJob.perform_now(id)
  end

  def bust_cache
    Comments::BustCacheJob.perform_later(id)
  end

  def synchronous_bust
    commentable.touch(:last_comment_at) if commentable.respond_to?(:last_comment_at)
    cache_buster = CacheBuster.new
    cache_buster.bust(commentable.path.to_s) if commentable
    expire_root_fragment
  end

  def send_email_notification
    Comments::SendEmailNotificationJob.perform_later(id)
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
