module Notifications
  # Reports one reaction or follow notification once it has stopped changing
  # (see Notifications::SyncEvents.debounce). Each new job replaces the one
  # still scheduled for the same row, which makes the debounce trailing.
  class SyncEventDebounceWorker
    include Sidekiq::Job

    FOLLOW = "Follow".freeze

    sidekiq_options queue: :low_priority, retry: 5, lock: :until_executing, on_conflict: :replace,
                    lock_args_method: :lock_args

    # A user has one follow notification, whose notifiable moves to the newest
    # follow on every re-aggregation, so follows coalesce per recipient.
    def self.lock_args(args)
      user_id, _notifiable_type, _notifiable_id, action = args
      action == FOLLOW ? [user_id, action] : args
    end

    def perform(user_id, notifiable_type, notifiable_id, action)
      notification = current_notification(user_id, notifiable_type, notifiable_id, action)
      return SyncEvents.sent(notification, recipients: { user_id => notification.id }) if notification

      SyncEvents.removed(
        notifiable_type: notifiable_type,
        notifiable_ids: [notifiable_id],
        action: action,
        recipients: { user_id => nil },
        reason: action == FOLLOW ? "follow_removed" : "reaction_removed",
      )
    end

    private

    def current_notification(user_id, notifiable_type, notifiable_id, action)
      scope = Notification.where(user_id: user_id, action: action)
      scope = scope.where(notifiable_type: notifiable_type, notifiable_id: notifiable_id) unless action == FOLLOW
      scope.first
    end
  end
end
