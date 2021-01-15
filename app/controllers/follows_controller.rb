class FollowsController < ApplicationController
  after_action :verify_authorized

  def show
    skip_authorization
    render(plain: "not-logged-in") && return unless current_user

    if current_user.id == params[:id].to_i && params[:followable_type] == "User"
      render plain: "self"
      return
    end

    following_them_check = Follows::CheckCached.call(current_user, params[:followable_type], params[:id])

    return render plain: following_them_check unless params[:followable_type] == "User"

    following_you_check = Follows::CheckCached.call(User.find_by(id: params[:id]), params[:followable_type],
                                                    current_user.id)

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
        following_them_check = Follows::CheckCached.call(current_user, params[:followable_type], id)
        following_you_check = Follows::CheckCached.call(User.find_by(id: id), params[:followable_type],
                                                        current_user.id)
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

  def bulk_update
    @follows = Follow.where(id: params_for_update.keys).includes(:follower, :followable)
    authorize @follows
    Follow.transaction do
      @follows.each { |follow| follow.update!(params_for_update[follow.id.to_s]) }
    end
    redirect_to dashboard_following_path
  end

  private

  def follows_params
    params.permit(follows: policy(Follow).permitted_attributes)
  end

  def params_for_update
    follows_params[:follows].each_with_object({}) do |follow, params|
      params[follow[:id]] = follow.slice(:explicit_points)
    end
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
