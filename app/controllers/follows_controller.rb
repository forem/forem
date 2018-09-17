class FollowsController < ApplicationController
  after_action :verify_authorized

  def show
    skip_authorization
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
    authorize Follow
    followable = if params[:followable_type] == "Organization"
                   Organization.find(params[:followable_id])
                 elsif params[:followable_type] == "Tag"
                   Tag.find(params[:followable_id])
                 else
                   User.find(params[:followable_id])
                 end
    capture_param(:followable_type, :followable_id, :verb)
    @result = if params[:verb] == "unfollow"
                current_user.stop_following(followable)
                "unfollowed"
              else
                current_user.follow(followable)
                "followed"
              end
    current_user.save
    current_user.touch
    render json: { outcome: @result }
  end
end
