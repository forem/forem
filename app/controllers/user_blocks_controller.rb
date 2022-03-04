class UserBlocksController < ApplicationController
  before_action :check_sign_in_status
  after_action :verify_authorized

  def show
    skip_authorization

    if current_user.blocking?(params[:blocked_id].to_i)
      render json: { result: "blocking" }
    else
      render json: { result: "not-blocking" }
    end
  end

  def create
    authorize UserBlock
    @user_block = UserBlock.new(permitted_attributes(UserBlock))
    @user_block.blocker_id = current_user.id
    @user_block.config = "default"

    if @user_block.save
      current_user.stop_following(@user_block.blocked)
      @user_block.blocked.stop_following(current_user)
      render json: { result: "blocked" }
    else
      render json: { error: @user_block.errors_as_sentence, status: 422 }, status: :unprocessable_entity
    end
  end

  def destroy
    if current_user.blocking_others_count.zero?
      skip_authorization
      render json: { result: "not-blocking-anyone" }
      return
    end

    @user_block = UserBlock.find_by!(blocked_id: permitted_attributes(UserBlock)[:blocked_id], blocker: current_user)
    authorize @user_block

    if @user_block.destroy
      render json: { result: "unblocked" }
    else
      render json: { error: @user_block.errors_as_sentence, status: 422 }, status: :unprocessable_entity
    end
  end

  private

  def check_sign_in_status
    return if current_user

    skip_authorization
    render json: { result: "not-logged-in", status: 401 }, status: :unauthorized
  end
end
