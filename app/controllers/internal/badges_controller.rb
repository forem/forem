class Internal::BadgesController < Internal::ApplicationController
  layout "internal"

  def index
    @badges = Badge.all
  end

  def award_badges
    usernames = permitted_params[:usernames].split(/\s*,\s*/)
    badge_slug = permitted_params[:badge]
    message = permitted_params[:message_markdown].presence || "Congrats!"
    BadgeRewarder.award_badges(usernames, badge_slug, message)
    flash[:success] = "BadgeRewarder task ran!"
    redirect_to internal_badges_url
  end

  private

  def permitted_params
    params.permit(:usernames, :badge, :message_markdown)
  end
end
