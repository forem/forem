module Admin
  class BadgeAchievementsController < Admin::ApplicationController
    layout "admin"

    def index
      @q = BadgeAchievement
        .includes(:badge)
        .includes(:user)
        .order(created_at: :desc)
        .ransack(params[:q])
      @badge_achievements = @q.result.page(params[:page] || 1).per(15)
    end

    def destroy
      @badge_achievement = BadgeAchievement.find(params[:id])

      if @badge_achievement.destroy
        render json: { message: I18n.t("admin.badge_achievements_controller.deleted") }, status: :ok
      else
        render json: { error: "Something went wrong." }, status: :unprocessable_entity
      end
    end

    def award
      @all_badges = Badge.select(:title, :slug).order(title: :asc)
    end

    def award_badges
      if permitted_params[:badge].blank?
        raise ArgumentError,
              I18n.t("admin.badge_achievements_controller.award")
      end

      usernames = permitted_params[:usernames].downcase.split(/\s*,\s*/)
      include_default_description = permitted_params[:include_default_description] == "1"
      message = permitted_params[:message_markdown].presence ||
        I18n.t("admin.badge_achievements_controller.congrats", community: ::Settings::Community.community_name)
      BadgeAchievements::BadgeAwardWorker
        .perform_async(usernames,
                       permitted_params[:badge],
                       message,
                       include_default_description)

      flash[:success] = I18n.t("admin.badge_achievements_controller.rewarded")
      redirect_to admin_badge_achievements_path
    rescue ArgumentError => e
      flash[:danger] = e.message
      redirect_to admin_badge_achievements_path
    end

    private

    def permitted_params
      params.permit(:usernames, :badge, :message_markdown, :include_default_description)
    end
  end
end
