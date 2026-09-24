module Api
  module BadgeAchievementsController
    extend ActiveSupport::Concern

    def index
      achievements = BadgeAchievement.order(created_at: :desc).page(params[:page]).per(50)
      render json: achievements
    end

    def show
      achievement = BadgeAchievement.find(params[:id])
      render json: achievement
    end

    def create
      achievement = BadgeAchievement.new(badge_achievement_params)

      if achievement.save
        render json: achievement, status: :created
      elsif (existing = existing_achievement_for(achievement))
        render json: { errors: achievement.errors.full_messages, achievement_id: existing.id }, status: :conflict
      else
        render json: { errors: achievement.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      achievement = BadgeAchievement.find(params[:id])
      achievement.destroy
      head :no_content
    end

    private

    def badge_achievement_params
      params.require(:badge_achievement).permit(
        :user_id,
        :badge_id,
        :rewarding_context_message_markdown,
        :include_default_description,
        metadata: {},
      )
    end

    def existing_achievement_for(achievement)
      return unless achievement.errors.of_kind?(:badge_id, :taken)

      BadgeAchievement.find_by(user_id: achievement.user_id, badge_id: achievement.badge_id)
    end

    def require_admin
      authorize :badge_achievement, :api?
    end
  end
end
