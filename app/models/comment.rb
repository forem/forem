class Comment < ApplicationRecord
  has_ancestry
  belongs_to :commentable, polymorphic: true
  counter_culture :commentable
  belongs_to :user
  counter_culture :user
  has_many   :reactions, as: :reactable, dependent: :destroy
  has_many   :mentions, as: :mentionable, dependent: :destroy

  validates :body_markdown, presence: true, length: { in: 1..25000 },
                        uniqueness: { scope: [:user_id,
                                              :ancestry,
                                              :commentable_id,
                                              :commentable_type] }
  validates :commentable_id, presence: true
  validates :commentable_type, inclusion: { in: %w(Article PodcastEpisode) }
  validates :user_id, presence: true

  after_create   :after_create_checks
  after_save     :calculate_score
  after_save     :bust_cache
  before_destroy :bust_cache
  after_create   :send_email_notification
  after_create   :create_first_reaction
  after_create   :send_to_moderator
  before_save    :set_markdown_character_count
  before_create  :adjust_comment_parent_based_on_depth
  before_validation :evaluate_markdown

  include StreamRails::Activity
  as_activity

  def self.rooted_on(commentable_id, commentable_type)
    includes(:user, :commentable).
      where(commentable_id: commentable_id,
            ancestry: nil,
            commentable_type: commentable_type)
  end

  def path
    begin
      "/#{user.username}/comment/#{id_code_generated}"
    rescue
      "/404.html"
    end
  end

  def parent_or_root_article
    parent || commentable
  end

  def parent_user
    parent_or_root_article.user
  end

  def parent_type
    parent_or_root_article.class.name.downcase
                          .gsub('article', 'post')
                          .gsub('podcastepisode', 'episode')
  end

  def id_code_generated
    id.to_s(26)
  end

  # notifications

  def activity_notify
    if ancestors.empty? && user != commentable.user
      [StreamNotifier.new(commentable.user.id).notify]
    elsif ancestors
      # notify all ancestors unless it's yourself
      user_ids = ancestors.map(&:user_id).uniq - [user_id]
      user_ids.map do |id|
        StreamNotifier.new(id).notify
      end
    end
  end

  def custom_css
    MarkdownParser.new(body_markdown).tags_used.map do |t|
      Rails.application.assets["ltags/#{t}.css"].to_s
    end.join
  end

  def activity_object
    self
  end

  def activity_target
    return "comment_#{Time.now}"
  end

  def remove_from_feed
    if ancestors.empty? && user != commentable.user
      [User.find(commentable.user.id)&.touch(:last_notification_activity)]
    elsif ancestors
      user_ids = ancestors.map { |comment| comment.user.id }
      user_ids = user_ids.uniq.reject { |uid| uid == commentable.user.id }
      user_ids = user_ids.uniq.reject { |uid| uid == self.user_id }
      # filters out article author and duplicate users
      user_ids.map do |id|
        User.find(id)&.touch(:last_notification_activity)
      end
    end
  end

  def title
    ActionController::Base.helpers.truncate(ActionController::Base.helpers.strip_tags(processed_html), length: 60)
  end

  def video
    nil
  end

  # Andy: Administrate field
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
        text_color: user.text_color_hex,
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
    return if commentable_type == 'PodcastEpisode'
    return unless commentable.video.present?
    self.processed_html = processed_html.gsub(/(([0-9]:)?)(([0-5][0-9]|[0-9])?):[0-5][0-9]/) {|s| "<a href='#{commentable.path}?t=#{s}'>#{s}</a>"}
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
                    reactable_type: 'Comment',
                    category: 'like')
  end
  handle_asynchronously :create_first_reaction

  def bust_cache
    expire_root_fragment
    CacheBuster.new.bust("#{commentable.path}") if commentable
    CacheBuster.new.bust("#{commentable.path}/comments") if commentable
    async_bust
  end

  def async_bust
    expire_root_fragment
    commentable.touch
    CacheBuster.new.bust_comment(self)
    commentable.index!
  end
  handle_asynchronously :async_bust

  def send_email_notification
    NotifyMailer.new_reply_email(self).deliver if parent_email_exist?
  end
  handle_asynchronously :send_email_notification

  def parent_email_exist?
    parent_user && parent_user.email.present? &&
      parent_user.email_comment_notifications
  end

  def strip_url(url)
    url.sub!(%r{https://}, '') if url.include?('https://')
    url.sub!(%r{http://}, '')  if url.include?('http://')
    url.sub!(/www./, '')       if url.include?('www.')
    url = url.truncate(37) unless url.include?(' ')
    url
  end

  def set_markdown_character_count
    # body_markdown is actually markdown, but that's a separate issue to be fixed soon
    self.markdown_character_count = body_markdown.size
  end
end
