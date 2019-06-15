class NotificationSubscription < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true
  validates :notifiable_type, inclusion: { in: %w[Comment Article] }
  validates :user_id, uniqueness: { scope: %i[notifiable_type notifiable_id] }
  validates :config, inclusion: { in: %w[all_comments top_level_comments only_author_comments] }
end
