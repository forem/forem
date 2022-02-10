#  @note When we destroy the related user, it's using dependent:
#        :delete for the relationship.  That means no before/after
#        destroy callbacks will be called on this object.
#
# @note When we destroy the related article, it's using dependent:
#       :delete for the relationship.  That means no before/after
#       destroy callbacks will be called on this object.
class Mention < ApplicationRecord
  belongs_to :user
  belongs_to :mentionable, polymorphic: true

  validates :user_id, uniqueness: { scope: %i[mentionable_id mentionable_type] }
  validates :mentionable_type, presence: true
  validate :permission

  after_create_commit :send_email_notification

  def self.create_all(notifiable)
    Mentions::CreateAllWorker.perform_async(notifiable.id, notifiable.class.name)
  end

  private

  def send_email_notification
    user = User.find(user_id)
    return unless user.email.present? && user.notification_setting.email_mention_notifications

    Mentions::SendEmailNotificationWorker.perform_async(id)
  end

  def permission
    errors.add(:mentionable_id, I18n.t("models.mention.is_not_valid")) unless mentionable&.valid?
  end
end
