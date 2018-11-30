class DashboardsController < ApplicationController
  before_action :set_no_cache_header
  before_action :authenticate_user!
  after_action :verify_authorized

  def show
    @user = if params[:username] && current_user.admin?
              User.find_by_username(params[:username])
            else
              current_user
            end
    authorize (@user || User), :dashboard_show?
    if params[:which] == "following" || params[:which] == "following_users"
      @follows = @user.follows_by_type("User").
        order("created_at DESC").includes(:followable).limit(80)
      @followed_tags = @user.follows_by_type("ActsAsTaggableOn::Tag").
        order("points DESC").includes(:followable).limit(80)
    elsif params[:which] == "user_followers"
      @follows = Follow.where(followable_id: @user.id, followable_type: "User").
        includes(:follower).order("created_at DESC").limit(80)
    elsif params[:which] == "organization_user_followers"
      @follows = Follow.where(followable_id: @user.organization_id, followable_type: "Organization").
        includes(:follower).order("created_at DESC").limit(80)
    elsif @user&.organization && @user&.org_admin && params[:which] == "organization"
      @articles = @user.organization.articles.order("created_at DESC").decorate
    elsif @user
      @articles = @user.articles.order("created_at DESC").decorate
    end
    # Updates analytics in background if appropriate:
    ArticleAnalyticsFetcher.new.delay.update_analytics(current_user.id) if @articles
  end
end
