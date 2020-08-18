module Admin
  class BadgeAchievementsController < Admin::ApplicationController
    layout "admin"

    def award
      @badge = Badge.all
    end

    def award_badges
      raise ArgumentError, "Please choose a badge to award" if permitted_params[:badge].blank?

      usernames = permitted_params[:usernames].downcase.split(/\s*,\s*/)
      message = permitted_params[:message_markdown].presence || "Congrats!"
      BadgeAchievements::BadgeAwardWorker.perform_async(usernames, permitted_params[:badge], message)

      flash[:success] = "Badges are being rewarded. The task will finish shortly."
      redirect_to admin_badge_achievements_path
    rescue ArgumentError => e
      flash[:danger] = e.message
      redirect_to admin_badge_achievements_path
    end

    private

    def badge_params
      params.permit(:usernames, :badge, :message_markdown)
    end
  end
end
