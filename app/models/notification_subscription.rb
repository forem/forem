class NotificationSubscription < ApplicationRecord
  belongs_to :notifiable, polymorphic: true
  belongs_to :user

  validates :config, presence: true, inclusion: { in: %w[all_comments top_level_comments only_author_comments] }
  validates :notifiable_id, presence: true
  validates :notifiable_type, presence: true, inclusion: { in: %w[Comment Article] }
  validates :user_id, uniqueness: { scope: %i[notifiable_type notifiable_id] }
end
