module Stories
  class PinsController < ApplicationController
    def update
      Settings::General.feed_pinned_article_id = params[:id]
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy
      Settings::General.feed_pinned_article_id = nil
    end
  end
end
