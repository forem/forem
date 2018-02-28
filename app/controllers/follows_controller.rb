class FollowsController < ApplicationController
  skip_before_action :ensure_signup_complete

  def show
    unless current_user
      render plain: "not-logged-in"
      return
    end
    if current_user.id == params[:id].to_i && params[:followable_type] == "User"
      render plain: "self"
      return
    end
    render plain: FollowChecker.new(current_user, params[:followable_type], params[:id]).cached_follow_check
  end

  def create
    if params[:followable_type] == "Organization"
      followable = Organization.find(params[:followable_id])
    elsif params[:followable_type] == "Tag"
      followable = Tag.find(params[:followable_id])
    else
      followable = User.find(params[:followable_id])
    end
    if params[:verb] == "unfollow"
      current_user.stop_following(followable)
      @result = "unfollowed"
    else
      current_user.follow(followable)
      @result = "followed"
    end
    current_user.save
    current_user.touch
    render json: { outcome: @result }
  end
end
