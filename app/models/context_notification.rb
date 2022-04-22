# This model was created to track notifications for which events have been sent already.
# E.g. when a notification about a published article is sent (a Notification record is created),
# we create a ContextNotification record where context_id is the article id,
# context_type is "Article", and action is "Published".
# Currently, context notifications are created only for notifications about published articles.
class ContextNotification < ApplicationRecord
  belongs_to :context, polymorphic: true

  validates :action, presence: true, inclusion: { in: %w[Published] }
  validates :context_type, presence: true, inclusion: { in: %w[Article] }
  validates :context_id, uniqueness: { scope: %i[context_type action] }
end
