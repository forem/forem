class ChatChannelRequestManagerController < ApplicationController
  after_action :verify_authorized

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def request_details
    @membership = ChatChannelMembership.find_by(id: params[:membership_id], user_id: current_user.id)
    authorize @membership
    @channel = @membership.chat_channel
    @user_joining_requests = ChatChannelMembership.where(user_id: current_user.id, status: %w[joining_request pending])
  end

  private

  def user_not_authorized
    render json: { success: false, message: "User not authorized" }, status: :unauthorized
  end

  def record_not_found
    render json: { success: false, message: "not found" }, status: :not_found
  end
end
