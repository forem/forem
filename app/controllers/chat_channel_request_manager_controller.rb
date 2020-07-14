class ChatChannelRequestManagerController < ApplicationController
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def request_details
    mod_memberships = ChatChannelMembership.where(user_id: current_user.id, role: "mod", status: "active")
    user_chat_channels = mod_memberships.map(&:chat_channel)
    @memberships = user_chat_channels.map(&:requested_memberships).flatten
    @user_invitations = ChatChannelMembership.where(user_id: current_user.id, status: %w[pending]).order("created_at DESC")
  end

  private

  def user_not_authorized
    render json: { success: false, message: "User not authorized" }, status: :unauthorized
  end

  def record_not_found
    render json: { success: false, message: "not found" }, status: :not_found
  end
end
