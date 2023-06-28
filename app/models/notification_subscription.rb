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
  validates :notifiable_type, presence: true, inclusion: { in: %w[Comment Article] }
  validates :user_id, uniqueness: { scope: %i[notifiable_type notifiable_id] }

  def self.for_notifiable(notifiable = nil, notifiable_type: nil, notifiable_id: nil)
    notifiable_type ||= notifiable&.class&.polymorphic_name
    notifiable_id ||= notifiable&.id

    return none if !notifiable_type || !notifiable_id

    where(notifiable_type: notifiable_type, notifiable_id: notifiable_id)
  end

  class << self
    # @param notifiable [Comment, Article]
    #
    # @see notifiable_type's validation
    def update_notification_subscriptions(notifiable)
      NotificationSubscriptions::UpdateWorker.perform_async(
        notifiable.id,
        notifiable.class.name,
      )
    end
  end
end
