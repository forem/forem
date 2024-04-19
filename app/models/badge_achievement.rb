#  @note When we destroy the related user, it's using dependent:
#        :delete for the relationship.  That means no before/after
#        destroy callbacks will be called on this object.
class BadgeAchievement < ApplicationRecord
  resourcify

  belongs_to :user
  belongs_to :badge
  belongs_to :rewarder, class_name: "User", optional: true

  delegate :slug, to: :badge, prefix: true
  delegate :title, to: :badge, prefix: true
  delegate :badge_image_url, to: :badge, prefix: false

  counter_culture :user, column_name: "badge_achievements_count"

  validates :badge_id, uniqueness: { scope: :user_id, if: :single_award_badge? }

  before_validation :render_rewarding_context_message_html
  after_create :award_credits
  after_create_commit :notify_recipient
  after_create_commit :send_email_notification

  private

  def render_rewarding_context_message_html
    return unless rewarding_context_message_markdown

    parsed_markdown = MarkdownProcessor::Parser.new(rewarding_context_message_markdown)
    html = parsed_markdown.finalize
    final_html = ActionController::Base.helpers.sanitize(
      html,
      tags: MarkdownProcessor::AllowedTags::BADGE_ACHIEVEMENT_CONTEXT_MESSAGE,
      attributes: MarkdownProcessor::AllowedAttributes::BADGE_ACHIEVEMENT_CONTEXT_MESSAGE,
    )

    self.rewarding_context_message = final_html
  end

  def notify_recipient
    Notification.send_new_badge_achievement_notification(self)
  end

  def send_email_notification
    return unless user.is_a?(User)
    return unless user.email && user.notification_setting.email_badge_notifications

    BadgeAchievements::SendEmailNotificationWorker.perform_async(id)
  end

  def award_credits
    return if badge.credits_awarded.zero?

    Credit.add_to(user, badge.credits_awarded)
  end

  def single_award_badge?
    badge&.allow_multiple_awards == false
  end
end
