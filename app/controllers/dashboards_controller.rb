class DashboardsController < ApplicationController
  before_action :set_no_cache_header
  before_action :authenticate_user!
  after_action :verify_authorized

  def show
    fetch_and_authorize_user
    if params[:which] == "user_followers"
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

  def following
    fetch_and_authorize_user
    @follows = @user.follows_by_type("User").
      order("created_at DESC").includes(:followable).limit(80)
    @followed_tags = @user.follows_by_type("ActsAsTaggableOn::Tag").
      order("points DESC").includes(:followable).limit(80)
    @followed_organizations = @user.follows_by_type("Organization").
      order("created_at DESC").includes(:followable).limit(80)
  end

  def followers
    fetch_and_authorize_user
    if params[:which] == "user_followers"
      @follows = Follow.where(followable_id: @user.id, followable_type: "User").
        includes(:follower).order("created_at DESC").limit(80)
    elsif params[:which] == "organization_user_followers"
      @follows = Follow.where(followable_id: @user.organization_id, followable_type: "Organization").
        includes(:follower).order("created_at DESC").limit(80)
    end
  end

  def pro
    user_or_org = if params[:org_id]
                    org = Organization.find_by(id: params[:org_id])
                    authorize org, :pro_org_user?
                    org
                  else
                    authorize current_user, :pro_user?
                    current_user
                  end
    @dashboard = Dashboard::Pro.new(user_or_org)
  end

  private

  def fetch_and_authorize_user
    @user = if params[:username] && current_user.any_admin?
              User.find_by(username: params[:username])
            else
              current_user
            end
    authorize (@user || User), :dashboard_show?
  end
end
