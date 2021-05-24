module Stories
  class PinnedArticlesController < ApplicationController
    before_action :authenticate_user!
    after_action :verify_authorized

    def show
      authorize :pinned_article

      if Settings::General.feed_pinned_article_id.present?
        article = Settings::General.feed_pinned_article
        setting = Settings::General.find_by(var: :feed_pinned_article_id)

        render json: {
          id: article.id,
          path: article.path,
          title: article.title,
          pinned_at: setting.updated_at.iso8601
        }
      else
        render json: { error: "not found" }, status: :not_found
      end
    end

    def update
      authorize :pinned_article

      Settings::General.feed_pinned_article_id = params[:id]
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy
      authorize :pinned_article

      Settings::General.feed_pinned_article_id = nil
    end
  end
end
