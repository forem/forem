class Internal::BadgesController < Internal::ApplicationController
  layout "internal"
  before_action :ensure_badge, only: :award_badges

  def index
    @badges = Badge.all
  end

  def award_badges
    usernames = permitted_params[:usernames].split(/\s*,\s*/)
    message = permitted_params[:message_markdown].presence || "Congrats!"
    BadgeRewarder.award_badges(usernames, permitted_params[:badge], message)
    flash[:success] = "BadgeRewarder task ran!"
    redirect_to internal_badges_url
  rescue ArgumentError => e
    flash[:danger] = e
    redirect_to "/internal/badges"
  end

  private

  def permitted_params
    params.permit(:usernames, :badge, :message_markdown)
  end

  def ensure_badge
    raise ArgumentError, "You must choose a badge to award" if permitted_params[:badge].blank?
  end
end
