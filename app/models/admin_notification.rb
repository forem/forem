# One notification pushed through the admin API (POST /api/admin/notifications).
# It is only the notifiable that every recipient's Notification row points at:
# sharing it keeps a push to many users one batched sync event, and the
# (user, notifiable, action) unique index still allows one row per recipient.
# Each row keeps its own content in json_data, so it can be edited per recipient.
class AdminNotification < ApplicationRecord
  has_many :notifications, as: :notifiable, inverse_of: :notifiable, dependent: :delete_all
end
