module Admin
  class BadgesController < Admin::ApplicationController
    layout "admin"

    ALLOWED_PARAMS = %i[
      title slug description badge_image
    ].freeze

    def index
      @badges = Badge.all
    end

    def edit
      @badge = Badge.find(params[:id])
    end

    def update
      @badge = Badge.find(params[:id])

      if @badge.update(badge_params)
        flash[:success] = "Badge has been updated!"
        redirect_to internal_badges_path
      else
        flash[:danger] = @badge.errors.full_messages.to_sentence
        render :edit
      end
    end

    def award_badges
      raise ArgumentError, "Please choose a badge to award" if permitted_params[:badge].blank?

      usernames = permitted_params[:usernames].split(/\s*,\s*/)
      message = permitted_params[:message_markdown].presence || "Congrats!"
      BadgeAchievements::BadgeAwardWorker.perform_async(usernames, permitted_params[:badge], message)

      flash[:success] = "Badges are being rewarded. The task will finish shortly."
      redirect_to internal_badges_path
    rescue ArgumentError => e
      flash[:danger] = e.message
      redirect_to internal_badges_path
    end

    def award
      @badge = Badge.all
    end

    private

    private_constant :ALLOWED_PARAMS

    def badge_params
      allowed_params = ALLOWED_PARAMS
      params.require(:badge).permit(allowed_params)
    end

    def permitted_params
      params.permit(:usernames, :badge, :message_markdown)
    end
  end
end
