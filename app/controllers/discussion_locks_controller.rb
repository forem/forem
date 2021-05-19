class DiscussionLocksController < ApplicationController
  before_action :set_discussion_lock, only: %i[destroy]
  before_action :authenticate_user!

  DISCUSSION_LOCK_PARAMS = %i[article_id reason].freeze

  def create
    @discussion_lock = DiscussionLock.new(discussion_lock_params)
    # TODO: - authorize discussion lock
    if @discussion_lock.save
      render json: { message: "success", success: true, data: @discussion_lock }, status: :ok
    else
      render json: { error: @discussion_lock.errors_as_sentence, success: false }, status: :unprocessable_entity
    end
  end

  def destroy
    # TODO: - authorize discussion lock
    if @discussion_lock.destroy
      render json: { message: "success", success: true }, status: :ok
    else
      render json: { error: @discussion_lock.errors_as_sentence, success: false }, status: :unprocessable_entity
    end
  end

  private

  def set_discussion_lock
    @discussion_lock = DiscussionLock.find(params[:id])
  end

  def discussion_lock_params
    params.require(:discussion_lock).permit(DISCUSSION_LOCK_PARAMS).merge!(user_id: current_user.id)
  end
end
