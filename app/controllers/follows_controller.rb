class FollowsController < ApplicationController
  after_action :verify_authorized

  def show
    skip_authorization
    render(plain: "not-logged-in") && return unless current_user

    if current_user.id == params[:id].to_i && params[:followable_type] == "User"
      render plain: "self"
      return
    end

    following_them_check = FollowChecker.new(current_user, params[:followable_type], params[:id]).cached_follow_check

    return render plain: following_them_check unless params[:followable_type] == "User"

    following_you_check = FollowChecker.new(User.find_by(id: params[:id]), params[:followable_type],
                                            current_user.id).cached_follow_check

    if following_them_check && following_you_check
      render plain: "mutual"
    elsif following_you_check
      render plain: "follow-back"
    else
      render plain: following_them_check
    end
  end

  def bulk_show
    skip_authorization
    render(plain: "not-logged-in") && return unless current_user

    response = params.require(:ids).map(&:to_i).index_with do |id|
      if current_user.id == id
        "self"
      else
        following_them_check = FollowChecker.new(current_user, params[:followable_type], id).cached_follow_check
        following_you_check = FollowChecker.new(User.find_by(id: id), params[:followable_type],
                                                current_user.id).cached_follow_check
        if following_them_check && following_you_check
          "mutual"
        elsif following_you_check
          "follow-back"
        else
          following_them_check.to_s
        end
      end
    end

    render json: response
  end

  def create
    authorize Follow

    followable = case params[:followable_type]
                 when "Organization"
                   Organization.find(params[:followable_id])
                 when "Tag"
                   Tag.find(params[:followable_id])
                 when "Podcast"
                   Podcast.find(params[:followable_id])
                 else
                   User.find(params[:followable_id])
                 end

    need_notification = Follow.need_new_follower_notification_for?(followable.class.name)

    @result = if params[:verb] == "unfollow"
                unfollow(followable, need_notification: need_notification)
              else
                if rate_limiter.limit_by_action("follow_account")
                  render json: { error: "Daily account follow limit reached!" }, status: :too_many_requests
                  return
                end
                follow(followable, need_notification: need_notification)
              end

    render json: { outcome: @result }
  end

  def update
    @follow = Follow.find(params[:id])
    authorize @follow
    @follow.explicit_points = follow_params[:explicit_points]
    redirect_to dashboard_following_path if @follow.save
  end

  private

  def follow_params
    params.require(:follow).permit(policy(Follow).permitted_attributes)
  end

  def follow(followable, need_notification: false)
    user_follow = current_user.follow(followable)
    Notification.send_new_follower_notification(user_follow) if need_notification
    "followed"
  rescue ActiveRecord::RecordInvalid
    DatadogStatsClient.increment("users.invalid_follow")
    "already followed"
  end

  def unfollow(followable, need_notification: false)
    user_follow = current_user.stop_following(followable)
    Notification.send_new_follower_notification_without_delay(user_follow, is_read: true) if need_notification

    "unfollowed"
  end
end
