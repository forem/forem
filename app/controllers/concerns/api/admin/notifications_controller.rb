module Api
  module Admin
    # Admin API for pushing notifications to users and managing their read state.
    # Writes go through Notifications::SyncEvents like DEV's own, except the
    # read: that call carries the caller's own read state, so echoing it back
    # as a notifications_read event would make the caller consume its own push.
    module NotificationsController
      extend ActiveSupport::Concern

      # Precision of the timestamps the sync events carry; read_through covers
      # every row notified within the millisecond it names.
      READ_THROUGH_PRECISION = 0.001

      def create
        user_ids = recipient_ids!
        content = notification_content!(required: true)
        anchor, ids = Notifications::AdminNotifications::Send.call(user_ids: user_ids, content: content, actor: actor!)
        unless anchor
          raise Api::Admin::ApiError.new(:no_recipients_found, I18n.t("admin_api.errors.no_recipients_found"),
                                         status: 422)
        end

        @admin_notification = anchor
        @results = user_ids.map do |user_id|
          next { "user_id" => user_id, "status" => "not_found" } unless ids.key?(user_id)

          { "user_id" => user_id, "id" => ids[user_id], "status" => "created" }
        end

        audit!(slug: "create_notifications",
               data: {
                 "admin_notification_id" => anchor.id,
                 "recipient_count" => ids.size,
                 "not_found_count" => user_ids.size - ids.size
               })
        render :create, status: :created
      end

      def update
        notification = find_notification!
        unless notification.notifiable_type == Notifications::AdminNotifications::NOTIFIABLE_TYPE
          raise Api::Admin::ApiError.new(:notification_not_editable,
                                         I18n.t("admin_api.errors.notification_not_editable"), status: 422)
        end

        changes = notification_content!(required: false)
        @notification = Notifications::AdminNotifications::Update.call(notification, changes)

        audit!(slug: "update_notification",
               data: {
                 "notification_id" => notification.id,
                 "target_user_id" => notification.user_id,
                 "changed" => changes.keys
               })
        render :update, status: :ok
      end

      def destroy
        notification = find_notification!
        notification.delete
        if Notifications::SyncEvents.syncable?(notification)
          Notifications::SyncEvents.removed(
            notifiable_type: notification.notifiable_type,
            notifiable_ids: [notification.notifiable_id],
            action: notification.action,
            recipients: { notification.user_id => notification.id },
            reason: "admin_deleted",
          )
        end

        audit!(slug: "delete_notification",
               data: {
                 "notification_id" => notification.id,
                 "target_user_id" => notification.user_id,
                 "notifiable_type" => notification.notifiable_type,
                 "action" => notification.action
               })
        head :no_content
      end

      # Marks a user's unread notifications read up to a point, given as exactly
      # one of:
      #   up_to_id      a notification of that user: rows with id <= it that were
      #                 last notified no later than it. Reaction and follow rows
      #                 keep their id when they re-aggregate, so an id bound alone
      #                 would mark a newer re-notify the caller never saw.
      #   read_through  an ISO 8601 time: rows last notified at or before it.
      def read
        @target = User.select(:id).find(params[:user_id])
        scope = read_scope(@target.notifications.unread)
        @read_at = Time.current
        @marked_read = scope.update_all(read: true, read_at: @read_at)

        audit!(slug: "mark_notifications_read",
               data: {
                 "target_user_id" => @target.id,
                 "up_to_id" => params[:up_to_id].presence,
                 "read_through" => params[:read_through].presence,
                 "marked_read" => @marked_read
               })
        render :read, status: :ok
      end

      private

      def find_notification!
        Notification.find_by(id: params[:id]) ||
          raise(Api::Admin::ApiError.new(:notification_not_found,
                                         I18n.t("admin_api.errors.notification_not_found"), status: 404))
      end

      def recipient_ids!
        ids = params[:user_ids]
        max = Notifications::AdminNotifications::MAX_RECIPIENTS
        integers = Array(ids).map { |id| Integer(id.to_s, exception: false) } if ids.is_a?(Array)
        return integers.uniq if integers&.size&.between?(1, max) && integers.all? { |id| id&.positive? }

        raise Api::Admin::ApiError.new(:invalid_user_ids, I18n.t("admin_api.errors.invalid_user_ids", limit: max),
                                       status: 422)
      end

      def actor!
        return if params[:actor_id].blank?

        User.find_by(id: params[:actor_id]) ||
          raise(Api::Admin::ApiError.new(:actor_not_found, I18n.t("admin_api.errors.actor_not_found"), status: 422))
      end

      def notification_content!(required:)
        keys = Notifications::AdminNotifications::CONTENT_KEYS
        content = params.slice(*keys).permit(*keys).to_h.transform_values { |value| value.to_s.strip.presence }
        content["title"] ||= nil if required
        invalid = content.reject { |key, value| valid_content?(key, value) }.keys
        invalid << "content" if content.empty?
        return content if invalid.empty?

        raise Api::Admin::ApiError.new(
          :invalid_notification_content,
          I18n.t("admin_api.errors.invalid_notification_content",
                 fields: invalid.join(", "),
                 title_limit: Notifications::AdminNotifications::TITLE_LIMIT,
                 body_limit: Notifications::AdminNotifications::BODY_LIMIT),
          status: 422,
        )
      end

      def valid_content?(key, value)
        case key
        when "title" then value.present? && value.length <= Notifications::AdminNotifications::TITLE_LIMIT
        when "body" then value.nil? || value.length <= Notifications::AdminNotifications::BODY_LIMIT
        when "url" then value.nil? || valid_url?(value)
        end
      end

      # A same-site path or an absolute http(s) URL, so a link can never run script.
      def valid_url?(value)
        return false if value.length > Notifications::AdminNotifications::URL_LIMIT
        return value.start_with?("/") && !value.start_with?("//") unless value.match?(/\A[a-z][a-z0-9+.-]*:/i)

        uri = URI.parse(value)
        uri.is_a?(URI::HTTP) && uri.host.present?
      rescue URI::InvalidURIError
        false
      end

      def read_scope(unread)
        up_to_id = params[:up_to_id].presence
        read_through = params[:read_through].presence
        invalid_read_cutoff! unless up_to_id.nil? ^ read_through.nil?
        return read_through_scope(unread, read_through) if read_through

        bound_id = Integer(up_to_id.to_s, exception: false) || invalid_read_cutoff!
        bound = @target.notifications.select(:id, :notified_at).find_by(id: bound_id)
        unless bound
          raise Api::Admin::ApiError.new(:notification_not_found,
                                         I18n.t("admin_api.errors.notification_not_found"), status: 404)
        end

        unread.where(id: ..bound.id).where(notified_at: ..bound.notified_at)
      end

      def read_through_scope(unread, read_through)
        cutoff = Time.iso8601(read_through.to_s)
        unread.where(notifications: { notified_at: ...(cutoff + READ_THROUGH_PRECISION) })
      rescue ArgumentError
        invalid_read_cutoff!
      end

      def invalid_read_cutoff!
        raise Api::Admin::ApiError.new(:invalid_read_cutoff, I18n.t("admin_api.errors.invalid_read_cutoff"),
                                       status: 422)
      end
    end
  end
end
