class Mention < ApplicationRecord
  belongs_to :user
  belongs_to :mentionable, polymorphic: true

  validates :user_id, presence: true,
                      uniqueness: { scope: %i[mentionable_id
                                              mentionable_type] }
  validates :mentionable_id, presence: true
  validates :mentionable_type, presence: true
  validate :permission
  after_create :send_email_notification

  class << self
    def create_all(notifiable)
      Mentions::CreateAllJob.perform_later(notifiable.id, notifiable.class.name)
    end
  end

  def send_email_notification
    user = User.find(user_id)
    return unless user.email.present? && user.email_mention_notifications

    Mentions::SendEmailNotificationJob.perform_later(id)
  end

  def permission
    errors.add(:mentionable_id, "is not valid.") unless mentionable&.valid?
  end
end
