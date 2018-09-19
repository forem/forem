class Comment < ApplicationRecord
  has_ancestry
  include AlgoliaSearch
  belongs_to :commentable, polymorphic: true
  counter_culture :commentable
  belongs_to :user
  counter_culture :user
  has_many   :reactions, as: :reactable, dependent: :destroy
  has_many   :mentions, as: :mentionable, dependent: :destroy

  validates :body_markdown, presence: true, length: { in: 1..25000 },
                            uniqueness: { scope: %i[user_id
                                                    ancestry
                                                    commentable_id
                                                    commentable_type] }
  validates :commentable_id, presence: true
  validates :commentable_type, inclusion: { in: %w(Article PodcastEpisode) }
  validates :user_id, presence: true

  after_create   :after_create_checks
  after_save     :calculate_score
  after_save     :bust_cache
  before_destroy :before_destroy_actions
  after_create   :send_email_notification, if: :should_send_email_notification?
  after_create   :create_first_reaction
  after_create   :send_to_moderator
  before_save    :set_markdown_character_count
  before_create  :adjust_comment_parent_based_on_depth
  before_validation :evaluate_markdown
  validate :permissions

  include StreamRails::Activity
  as_activity

  algoliasearch per_environment: true, enqueue: :trigger_delayed_index do
    attribute :id
    add_index "ordered_comments",
                  id: :index_id,
                  per_environment: true,
                  enqueue: :trigger_delayed_index do
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

  def self.trigger_delayed_index(record, remove)
    if remove
      record.delay.remove_from_index! if record&.persisted?
    elsif record.deleted == false
      record.delay.index!
    else
      record.remove_algolia_index
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
    includes(:user, :commentable).
      select(:id, :user_id, :commentable_type, :commentable_id,
             :deleted, :created_at, :processed_html, :ancestry, :updated_at).
      where(commentable_id: commentable_id,
            ancestry: nil,
            commentable_type: commentable_type)
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

  # notifications

  def activity_notify
    user_ids = ancestors.map(&:user_id).to_set
    user_ids.add(commentable.user.id) if user_ids.empty?
    user_ids.delete(user_id).map { |id| StreamNotifier.new(id).notify }
  end

  def custom_css
    MarkdownParser.new(body_markdown).tags_used.map do |tag|
      Rails.application.assets["ltags/#{tag}.css"].to_s
    end.join
  end

  def activity_object
    self
  end

  def activity_target
    "comment_#{Time.now}"
  end

  def remove_from_feed
    super
    if ancestors.empty? && user != commentable.user
      [User.find_by(id: commentable.user.id)&.touch(:last_notification_activity)]
    elsif ancestors
      user_ids = ancestors.map { |comment| comment.user.id }
      user_ids = user_ids.uniq.reject { |uid| uid == commentable.user.id }
      user_ids = user_ids.uniq.reject { |uid| uid == user_id }
      # filters out article author and duplicate users
      user_ids.map do |id|
        User.find_by(id: id)&.touch(:last_notification_activity)
      end
    end
  end

  def title
    ActionController::Base.helpers.truncate(ActionController::Base.helpers.strip_tags(processed_html), length: 60)
  end

  def video
    nil
  end

  # Administrate field
  def name_of_user
    user.name
  end

  def readable_publish_date
    if created_at.year == Time.now.year
      created_at.strftime("%b %e")
    else
      created_at.strftime("%b %e '%y")
    end
  end

  def sharemeow_link
    user_image = ProfileImage.new(user)
    user_image_link = Rails.env.production? ? user_image.get_link : user_image.get_external_link
    ShareMeowClient.image_url(
      template: "DevComment",
      options: {
        content: body_markdown || processed_html,
        name: user.name,
        subject_name: commentable.title,
        user_image_link: user_image_link,
        background_color: user.bg_color_hex,
        text_color: user.text_color_hex
      },
    )
  end

  private

  def send_to_moderator
    return if user && user.comments_count > 10
    ModerationService.new.send_moderation_notification(self)
  end

  def evaluate_markdown
    fixed_body_markdown = MarkdownFixer.modify_hr_tags(body_markdown)
    parsed_markdown = MarkdownParser.new(fixed_body_markdown)
    self.processed_html = parsed_markdown.finalize
    wrap_timestamps_if_video_present!
    shorten_urls!
  end

  def adjust_comment_parent_based_on_depth
    if parent && (parent.depth > 1 && parent.has_children?)
      self.parent_id = parent.descendant_ids.last
    end
  end

  def wrap_timestamps_if_video_present!
    return unless commentable_type != "PodcastEpisode" && commentable.video.present?
    self.processed_html = processed_html.gsub(/(([0-9]:)?)(([0-5][0-9]|[0-9])?):[0-5][0-9]/) { |s| "<a href='#{commentable.path}?t=#{s}'>#{s}</a>" }
  end

  def shorten_urls!
    doc = Nokogiri::HTML.parse(processed_html)
    # raise doc.to_s
    doc.css("a").each do |a|
      unless a.to_s.include?("<img") || a.attr("class")&.include?("ltag")
        a.content = strip_url(a.content) unless a.to_s.include?("<img")
      end
    end
    self.processed_html = doc.to_html.html_safe
  end

  def calculate_score
    update_column(:score, BlackBox.comment_quality_score(self))
    update_column(:spaminess_rating, BlackBox.calculate_spaminess(self))
    root.save unless is_root?
  end
  handle_asynchronously :calculate_score

  def after_create_checks
    create_id_code
    touch_user
  end

  def create_id_code
    update_column(:id_code, id.to_s(26))
  end
  handle_asynchronously :create_id_code

  def touch_user
    user.touch
  end
  handle_asynchronously :touch_user

  def expire_root_fragment
    root.touch
  end

  def create_first_reaction
    Reaction.create(user_id: user_id,
                    reactable_id: id,
                    reactable_type: "Comment",
                    category: "like")
  end
  handle_asynchronously :create_first_reaction

  def before_destroy_actions
    bust_cache
    remove_algolia_index
    reactions.destroy_all
  end

  def bust_cache
    expire_root_fragment
    cache_buster = CacheBuster.new
    cache_buster.bust(commentable.path.to_s) if commentable
    cache_buster.bust("#{commentable.path}/comments") if commentable
    async_bust
  end

  def async_bust
    expire_root_fragment
    commentable.touch
    commentable.touch(:last_comment_at)
    CacheBuster.new.bust_comment(self)
    commentable.index!
  end
  handle_asynchronously :async_bust

  def send_email_notification
    NotifyMailer.new_reply_email(self).deliver
  end
  handle_asynchronously :send_email_notification

  def should_send_email_notification?
    parent_user != user &&
      parent_user.email_comment_notifications &&
      parent_user.email
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
    if commentable_type == "Article" && !commentable.published
      errors.add(:commentable_id, "is not valid.")
    end
  end
end
