class DashboardsController < ApplicationController
  before_action :set_no_cache_header
  def show
    @user = if params[:username] && current_user_is_admin?
              User.find_by_username(params[:username])
            else
              current_user
            end
    if params[:which] == "following_users"
      @users = @user.following_users
    elsif params[:which] == "user_followers"
      @users = @user.user_followers
    elsif @user&.organization && @user.org_admin && params[:which] == "organization"
      @articles = @user.organization.articles.order("created_at DESC").decorate
    elsif @user
      @articles = @user.articles.order("created_at DESC").decorate
    else
      redirect_to "/enter"
    end
  end
end
