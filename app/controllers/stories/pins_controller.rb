module Stories
  class PinsController < ApplicationController
    before_action :authenticate_user!
    after_action :verify_authorized

    def update
      authorize :pin

      Settings::General.feed_pinned_article_id = params[:id]
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy
      authorize :pin

      Settings::General.feed_pinned_article_id = nil
    end
  end
end
