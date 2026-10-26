module Notifications
  class ReadsController < ApplicationController
    before_action :current_user_by_token, only: [:create]
    skip_before_action :verify_authenticity_token, if: :token_authenticated?

    def create
      render plain: "" && return unless current_user

      now = Time.current
      current_user.notifications.unread.update_all(read: true, read_at: now)
      current_user.touch(:last_notification_activity)

      if params[:org_id] && current_user.org_member?(params[:org_id])
        org = Organization.find_by(id: params[:org_id])
        # Org notifications always have a NULL user_id (see Notification.for_organization).
        # Scoping on both columns lets Postgres seek the (user_id, organization_id, ...)
        # index instead of scanning all of it for a non-leading organization_id.
        Notification.for_organization(org.id).unread.update_all(read: true, read_at: now)
      end

      render plain: "read"
    end
  end
end
