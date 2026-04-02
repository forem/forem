module Notifications
  class ReadsController < ApplicationController
    before_action :current_user_by_token, only: [:create]
    skip_before_action :verify_authenticity_token, if: :token_authenticated?

    def create
      render plain: "" && return unless current_user

      current_user.notifications.unread.update_all(read: true, read_at: Time.current)
      current_user.touch(:last_notification_activity)

      if params[:org_id] && current_user.org_member?(params[:org_id])
        org = Organization.find_by(id: params[:org_id])
        org.notifications.unread.update_all(read: true, read_at: Time.current)
      end

      render plain: "read"
    end
  end
end
