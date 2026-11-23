module Notifications
  # Mirrors writes to users' notifications as batched Trackable events
  # (Trackable::BatchEvent), so a downstream consumer can keep its own copy of
  # each user's notification list:
  #
  #   notifications_sent     rows created or re-notified, one event per fan-out
  #   notifications_updated  stored content refreshed after an edit
  #   notifications_removed  rows deleted (retention and user deletion excluded)
  #   notifications_read     a user marked their notifications, or one of them, read
  #
  # Every event is about many people, so it carries a fixed anonymous id instead
  # of a person's identity and names recipients by user id, each beside the id
  # of their notification row when Forem knows it; the adapter decides which
  # recipients may leave Forem. Only user-owned rows are sent, and never
  # moderator queue work. Off unless the notification_sync_events flag is on.
  module SyncEvents
    FLAG = :notification_sync_events
    ANONYMOUS_ID = "dev:notifications".freeze
    SCHEMA_VERSION = 1
    MAX_NOTIFIABLE_IDS = 1_000
    DEBOUNCE_DELAY = 60.seconds
    EXCLUDED_ACTIONS = %w[Moderation].freeze

    class << self
      def enabled?
        FeatureFlag.enabled?(FLAG)
      end

      def syncable?(notification)
        notification.user_id.present? && EXCLUDED_ACTIONS.exclude?(notification.action)
      end

      # @param notification [Notification] a row every recipient received, apart
      #   from user_id and id; it need not be persisted (fan-outs upsert attributes)
      # @param recipients [Hash{Integer => Integer}] each recipient's user id and
      #   the id of their notification row
      def sent(notification, recipients:)
        return unless enabled? && syncable?(notification)

        recipients = recipients.except(nil)
        return if recipients.empty?

        notified_at = iso8601(notification.notified_at || Time.current)
        properties = envelope(notified_at)
          .merge("dispatch_id" => SecureRandom.uuid)
          .merge(key(notification))
          .merge("notified_at" => notified_at, "read" => notification.read == true)
          .merge(SyncEventPresenter.new(notification).to_h)

        deliver("notifications_sent", properties, recipients)
      end

      # Applies to every recipient's row with the notification's notifiable and action.
      #
      # @param notification [Notification] carrying the refreshed json_data
      def updated(notification)
        return unless enabled?

        presented = SyncEventPresenter.new(notification).to_h
        properties = envelope(iso8601(Time.current))
          .merge(key(notification))
          .merge(presented.slice("text", "url"))

        deliver("notifications_updated", properties)
      end

      # @param action [String, nil] ignored when all_actions is true
      # @param recipients [Hash{Integer => Integer, nil}, nil] each recipient's
      #   user id and removed row id (nil when the row is already gone); nil
      #   removes the rows of every recipient. When set, notifiable_ids must fit
      #   in one chunk
      # @param reason [String] informational
      def removed(notifiable_type:, notifiable_ids:, reason:, action: nil, all_actions: false, recipients: nil)
        return unless enabled?

        notifiable_ids = Array.wrap(notifiable_ids).compact.uniq
        return if notifiable_ids.empty?

        base = envelope(iso8601(Time.current)).merge(
          "removal_id" => SecureRandom.uuid,
          "notifiable_type" => notifiable_type,
          "action" => action,
          "all_actions" => all_actions,
          "reason" => reason,
        )
        chunks = notifiable_ids.each_slice(MAX_NOTIFIABLE_IDS).to_a
        chunks.each_with_index do |ids, index|
          properties = base.merge("chunk_index" => index, "chunk_count" => chunks.size, "notifiable_ids" => ids)
          deliver("notifications_removed", properties, recipients)
        end
      end

      def read_all(user_id:, read_at:)
        read(user_id, read_at, "scope" => "all")
      end

      def read_one(notification, read_at: Time.current)
        return unless syncable?(notification)

        read(notification.user_id, read_at, { "scope" => "notification" }.merge(key(notification)), notification.id)
      end

      # Reaction and follow rows re-aggregate on every reaction or follow, so
      # they are reported once the row has been quiet for DEBOUNCE_DELAY, with
      # its state at that moment (or as removed when it is gone by then).
      def debounce(user_id:, notifiable_type:, notifiable_id:, action:)
        return unless enabled? && user_id

        Notifications::SyncEventDebounceWorker.perform_in(
          DEBOUNCE_DELAY, user_id, notifiable_type, notifiable_id, action
        )
      end

      private

      def read(user_id, read_at, properties, notification_id = nil)
        return unless enabled?

        read_at = iso8601(read_at)
        properties = envelope(read_at).merge("user_id" => user_id, "read_at" => read_at).merge(properties)
        deliver("notifications_read", properties, { user_id => notification_id })
      end

      def envelope(occurred_at)
        { "schema_version" => SCHEMA_VERSION, "occurred_at" => occurred_at }
      end

      def key(notification)
        {
          "notifiable_type" => notification.notifiable_type,
          "notifiable_id" => notification.notifiable_id,
          "action" => notification.action
        }
      end

      def iso8601(time)
        time.utc.iso8601(3)
      end

      # notification_ids travels aligned with recipient_user_ids, and stays nil
      # when no recipient's row id is known.
      def deliver(event_name, properties, recipients = nil)
        notification_ids = recipients&.values
        Trackable::BatchEvent.enqueue(
          event_name,
          properties: properties.merge("recipient_user_ids" => nil, "notification_ids" => nil),
          anonymous_id: ANONYMOUS_ID,
          recipient_ids: recipients&.keys,
          recipient_properties: notification_ids&.any? ? { "notification_ids" => notification_ids } : {},
        )
      end
    end
  end
end
