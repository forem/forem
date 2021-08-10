class DiscussionLocksController < ApplicationController
  before_action :authenticate_user!

  DISCUSSION_LOCK_PARAMS = %i[article_id notes reason].freeze

  def create
    @discussion_lock = DiscussionLock.new(discussion_lock_params)

    authorize @discussion_lock
    article = Article.find(discussion_lock_params[:article_id])
    authorize article, :discussion_lock_confirm?

    if @discussion_lock.save
      bust_article_cache(article)

      flash[:success] = "Discussion was successfully locked!"
    else
      flash[:error] = "Error: #{@discussion_lock.errors_as_sentence}"
    end

    redirect_to "#{article.path}/manage"
  end

  def destroy
    discussion_lock = DiscussionLock.find(params[:id])

    authorize discussion_lock
    article = discussion_lock.article

    if discussion_lock.destroy
      bust_article_cache(article)

      flash[:success] = "Discussion was successfully unlocked!"
    else
      flash[:error] = "Error: #{discussion_lock.errors_as_sentence}"
    end

    redirect_to "#{article.path}/manage"
  end

  private

  def discussion_lock_params
    params.require(:discussion_lock).permit(DISCUSSION_LOCK_PARAMS).merge(locking_user_id: current_user.id)
  end

  def bust_article_cache(article)
    EdgeCache::BustArticle.call(article)
  end
end
