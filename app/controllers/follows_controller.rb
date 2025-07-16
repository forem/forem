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

    followable_klass = case params[:followable_type].capitalize
                       when "Organization", "Tag", "Podcast", "Subforem"
                         params[:followable_type].capitalize.constantize
                       else
                         User
                       end

    followable = followable_klass.find(params[:followable_id])

    need_notification = Follow.need_new_follower_notification_for?(followable.class.name)

    @result = if params[:verb] == "unfollow"
                unfollow(followable, params[:followable_type], need_notification: need_notification)
              else
                if rate_limiter.limit_by_action("follow_account")
                  render json: { error: I18n.t("follows_controller.daily_limit") },
                         status: :too_many_requests
                  return
                end
                follow(followable, need_notification: need_notification)
              end

    clear_followed_tag_caches if followable_klass == Tag

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
    user_follow.update!(explicit_points: params[:explicit_points]) if params[:explicit_points].present?
    Notification.send_new_follower_notification(user_follow) if need_notification
    I18n.t("follows_controller.followed")
  rescue ActiveRecord::RecordInvalid
    ForemStatsClient.increment("users.invalid_follow")
    I18n.t("follows_controller.already_followed")
  end

  def clear_followed_tag_caches
    # Clear the followed_tags model cache, which is nested inside the async_info cache
    Rails.cache.delete("#{current_user.cache_key}-#{current_user.last_followed_at&.rfc3339}/followed_tags")
    # Clear the async_info cache, which contains the list of tags the user is currently following
    Rails.cache.delete("#{current_user.cache_key_with_version}/user-info")
  end

  def unfollow(followable, followable_type, need_notification: false)
    user_follow = current_user.stop_following(followable)
    Notification.send_new_follower_notification_without_delay(user_follow, is_read: true) if need_notification

    # Clear the user-follows-user cache async
    Follows::DeleteCached.call(current_user, followable_type, followable.id)

    I18n.t("follows_controller.unfollowed")
  end
end
