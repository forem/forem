#  @note When we destroy the related user, it's using dependent:
#        :delete for the relationship.  That means no before/after
#        destroy callbacks will be called on this object.
#
# @note When we destroy the related article, it's using dependent:
#       :delete for the relationship.  That means no before/after
#       destroy callbacks will be called on this object.
class NotificationSubscription < ApplicationRecord
  belongs_to :notifiable, polymorphic: true
  belongs_to :user

  validates :config, presence: true, inclusion: { in: %w[all_comments top_level_comments only_author_comments] }
  validates :notifiable_id, presence: true
  validates :notifiable_type, presence: true, inclusion: { in: %w[Comment Article] }
  validates :user_id, uniqueness: { scope: %i[notifiable_type notifiable_id] }

  class << self
    def update_notification_subscriptions(notifiable)
      NotificationSubscriptions::UpdateWorker.perform_async(
        notifiable.id,
        notifiable.class.name,
      )
    end
  end
end
