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
    elsif params[:followable_type] == "User" && FollowChecker.new(current_user, params[:followable_type], params[:id]).cached_follow_check && FollowChecker.new(User.find(params[:id]), params[:followable_type], current_user.id).cached_follow_check
      render plain: "mutual"
    elsif params[:followable_type] == "User" && FollowChecker.new(User.find(params[:id]), params[:followable_type], current_user.id).cached_follow_check
      render plain: "follow-back"
    else
      render plain: FollowChecker.new(current_user, params[:followable_type], params[:id]).cached_follow_check
    end
  end

  def create
    authorize Follow
    followable = if params[:followable_type] == "Organization"
                   Organization.find(params[:followable_id])
                 elsif params[:followable_type] == "Tag"
                   Tag.find(params[:followable_id])
                 elsif params[:followable_type] == "Podcast"
                   Podcast.find(params[:followable_id])
                 else
                   User.find(params[:followable_id])
                 end
    need_notification = Follow.need_new_follower_notification_for?(followable.class.name)
    @result = if params[:verb] == "unfollow"
                follow = current_user.stop_following(followable)
                Notification.send_new_follower_notification_without_delay(follow, true) if need_notification
                "unfollowed"
              else
                follow = current_user.follow(followable)
                Notification.send_new_follower_notification(follow) if need_notification
                "followed"
              end
    current_user.touch
    render json: { outcome: @result }
  end

  def update
    @follow = Follow.find(params[:id])
    authorize @follow
    redirect_to "/dashboard/following" if @follow.update(follow_params)
  end

  private

  def follow_params
    params.require(:follow).permit(policy(Follow).permitted_attributes)
  end
end
