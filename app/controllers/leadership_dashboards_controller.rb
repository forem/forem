class LeadershipDashboardsController < ApplicationController
  before_action :set_no_cache_header
  before_action :authenticate_user!

  SECTIONS = %w[community yours].freeze

  def show
    # Not discoverable by non-leaders
    return head :not_found unless current_user.community_leader?

    @section = SECTIONS.include?(params[:section]) ? params[:section] : "community"
    @favorite_allowance = current_user.favorite_allowance

    if @section == "yours"
      @favorited = Favorites::Fetch.call(user: current_user, page: params[:page])
    else
      @favorited = Favorites::Fetch.call(since: 24.hours.ago, page: params[:page])
    end
  end
end
