class LeadershipDashboardsController < ApplicationController
  before_action :set_no_cache_header
  before_action :authenticate_user!

  SECTIONS = %w[curation discussion].freeze

  def show
    # Not discoverable by non-leaders
    return head :not_found unless current_user.community_leader?

    @section = SECTIONS.include?(params[:section]) ? params[:section] : "curation"

    if @section == "discussion"
      setup_discussion
    else
      setup_curation
    end
  end

  private

  def setup_curation
    @favorite_allowance = current_user.favorite_allowance
    @favorited = Favorites::Fetch.call(user: current_user, page: params[:page])
  end

  def setup_discussion
    @discussion_feed = Articles::Feeds::EngagementCandidates.call(
      exclude_author: current_user, page: params[:page],
    )
  end
end
