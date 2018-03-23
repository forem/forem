class DashboardsController < ApplicationController
  before_action :set_no_cache_header
  def show
    @user = if params[:username] && current_user_is_admin?
              User.find_by_username(params[:username])
            else
              current_user
            end
    if params[:which] == "following_users"
      @follows = @user.follows_by_type("User").order("created_at DESC").includes(:followable).limit(500)
    elsif params[:which] == "user_followers"
      @follows = Follow.where(followable_id: @user.id).includes(:follower).order("created_at DESC").limit(500)
    elsif @user&.organization && @user.org_admin && params[:which] == "organization"
      @articles = @user.organization.articles.order("created_at DESC").decorate
    elsif @user
      @articles = @user.articles.order("created_at DESC").decorate
    else
      redirect_to "/enter"
    end
  end
end
