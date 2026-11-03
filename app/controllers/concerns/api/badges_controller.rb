module Api
  module BadgesController
    extend ActiveSupport::Concern

    def index
      badges = Badge.order(created_at: :desc).page(params[:page]).per(50)
      render json: badges
    end

    def show
      badge = Badge.find(params[:id])
      render json: badge
    end

    def create
      badge = Badge.new(badge_params)

      if badge.save
        Audit::Logger.log(:admin_api, @user, { "action" => "api_badge_create", "badge_id" => badge.id })
        render json: badge, status: :created
      else
        render json: { errors: badge.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      badge = Badge.find(params[:id])

      if badge.update(badge_params)
        Audit::Logger.log(:admin_api, @user, { "action" => "api_badge_update", "badge_id" => badge.id })
        render json: badge, status: :ok
      else
        render json: { errors: badge.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      badge = Badge.find(params[:id])
      badge.destroy
      if badge.destroyed?
        Audit::Logger.log(:admin_api, @user, { "action" => "api_badge_destroy", "badge_id" => badge.id })
      end
      head :no_content
    end

    private

    def badge_params
      params.require(:badge).permit(
        :title,
        :description,
        :badge_image,
        :remote_badge_image_url,
        :credits_awarded,
        :allow_multiple_awards,
      )
    end

    def require_admin
      authorize :badge, :api?
    end
  end
end
