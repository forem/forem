class DashboardsController < ApplicationController
  before_action :set_no_cache_header
  before_action :authenticate_user!
  def show
    @user = if params[:username] && current_user_is_admin?
              User.find_by_username(params[:username])
            else
              current_user
            end
    if params[:which] == "following_users"
      @follows = @user.follows_by_type("User").
        order("created_at DESC").includes(:followable).limit(80)
    elsif params[:which] == "user_followers"
      @follows = Follow.where(followable_id: @user.id, followable_type: "User").
        includes(:follower).order("created_at DESC").limit(80)
    elsif @user&.organization && @user.org_admin && params[:which] == "organization"
      @articles = @user.organization.articles.order("created_at DESC").decorate
    elsif @user
      @articles = @user.articles.order("created_at DESC").decorate
    end
  end
end
