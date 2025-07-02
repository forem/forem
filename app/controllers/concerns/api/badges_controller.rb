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
        render json: badge, status: :created
      else
        render json: { errors: badge.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      badge = Badge.find(params[:id])

      if badge.update(badge_params)
        render json: badge, status: :ok
      else
        render json: { errors: badge.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      badge = Badge.find(params[:id])
      badge.destroy
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
        :allow_multiple_awards
      )
    end

    def require_admin
      authorize :badge, :api?
    end
  end
end