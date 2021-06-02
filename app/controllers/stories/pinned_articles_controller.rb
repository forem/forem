module Stories
  class PinnedArticlesController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_user!
    after_action :verify_authorized

    after_action only: %i[update destroy] do
      Audit::Logger.log(:moderator, current_user, params.dup)
    end

    def show
      article = PinnedArticle.get

      if article.present?
        render json: {
          id: article.id,
          path: article.path,
          title: article.title,
          pinned_at: PinnedArticle.updated_at.iso8601
        }
      else
        render json: { error: "not found" }, status: :not_found
      end
    end

    def update
      article = Article.published.find(params[:id])

      PinnedArticle.set(article)
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy
      PinnedArticle.remove
    end

    private

    def authorize_user!
      authorize(current_user, policy_class: PinnedArticlePolicy)
    end
  end
end
