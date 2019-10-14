class UserBlocksController < ApplicationController
  before_action :check_sign_in_status
  after_action :verify_authorized

  def show
    skip_authorization

    if current_user.blocking?(params[:blocked_id].to_i)
      render plain: "blocking"
    else
      render plain: "not-blocking"
    end
  end

  def create

    authorize UserBlock
    @user_block = UserBlock.new(permitted_attributes(UserBlock))
    @user_block.blocker_id = current_user.id
    @user_block.config = "default"

    if @user_block.save
      block_chat_channel(@user_block.blocked_id)
      current_user.stop_following(@user_block.blocked)
      @user_block.blocked.stop_following(current_user)
      render json: { outcome: "blocked" }
    else
      render json: { outcome: "error: #{@user_block&.errors&.full_messages}" }
    end
  end

  def destroy
    if current_user.blocking_others_count.zero?
      skip_authorization
      render plain: "not-blocking-anyone"
      return
    end

    @user_block = UserBlock.find_by(blocked_id: permitted_attributes(UserBlock)[:blocked_id], blocker: current_user)
    authorize @user_block

    if @user_block.destroy
      unblock_chat_channel(@user_block.blocked_id)
      render json: { outcome: "unblocked" }
    else
      render json: { outcome: "error: #{@user_block&.errors&.full_messages}" }
    end
  end

  private

  def check_sign_in_status
    unless current_user
      skip_authorization
      render plain: "not-logged-in"
      return
    end
  end

  def get_potential_chat_channel(blocked_id)
    blocked_user = User.select(:id, :username).find(blocked_id)
    current_user.chat_channels.find_by("slug LIKE ? AND channel_type = ?", "%#{blocked_user.username}%", "direct")
  end

  def block_chat_channel(blocked_id)
    chat_channel = get_potential_chat_channel(blocked_id)
    return if chat_channel.blank?

    chat_channel.update(status: "blocked")
  end

  def unblock_chat_channel(blocked_id)
    chat_channel = get_potential_chat_channel(blocked_id)
    return if chat_channel.blank?

    chat_channel.update(status: "active")
  end
end
