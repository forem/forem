class DiscussionLocksController < ApplicationController
  before_action :authenticate_user!

  DISCUSSION_LOCK_PARAMS = %i[article_id reason].freeze

  def create
    @discussion_lock = DiscussionLock.new(discussion_lock_params)

    authorize @discussion_lock

    if @discussion_lock.save
      bust_article_cache_async(@discussion_lock.article_id)
      render json: { message: "success", success: true, data: @discussion_lock }, status: :ok
    else
      render json: { error: @discussion_lock.errors_as_sentence, success: false }, status: :unprocessable_entity
    end
  end

  def destroy
    discussion_lock = DiscussionLock.find(params[:id])

    authorize discussion_lock

    if discussion_lock.destroy
      bust_article_cache_async(discussion_lock.article_id)
      render json: { message: "success", success: true }, status: :ok
    else
      render json: { error: discussion_lock.errors_as_sentence, success: false }, status: :unprocessable_entity
    end
  end

  private

  def discussion_lock_params
    params.require(:discussion_lock).permit(DISCUSSION_LOCK_PARAMS).merge!(locking_user_id: current_user.id)
  end

  def bust_article_cache_async(article_id)
    Articles::BustCacheWorker.perform_async(article_id)
  end
end
