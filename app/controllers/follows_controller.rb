class FollowsController < ApplicationController
  before_action :current_user_by_token, only: [:create]
  skip_before_action :verify_authenticity_token, if: :token_authenticated?
  skip_before_action :remember_cookie_sync,
                     :forward_to_app_config_domain,
                     :redirect_custom_domain_non_profile_pages,
                     :determine_locale,
                     :set_request_signed_in_context,
                     only: %i[show bulk_show]
  after_action :verify_authorized

  MAX_BULK_FOLLOW_IDS = 500

  def show
    skip_authorization
    user_id = session_or_remembered_user_id(validate_salt: false)
    request.session_options[:skip] = true unless remembered_user_restored?
    render(plain: "not-logged-in") && return unless user_id

    target_id = params[:id].to_i
    is_user_type = params[:followable_type] == "User"
    viewer, users_by_id = load_bulk_show_users(user_id, [target_id], is_user_type)
    render(plain: "not-logged-in") && return unless viewer

    if viewer.id == target_id && is_user_type
      render plain: "self"
      return
    end

    unless is_user_type
      render plain: Follows::CheckCached.call(viewer, params[:followable_type], params[:id])
      return
    end

    # Follows::CheckCached only needs the follower's id and updated_at (for its cache key).
    # Reuse the target user loaded alongside the viewer and batch both directional checks
    # so cache misses don't re-query User.select(:id).find(...) or run two follows queries.
    followed_back_user = users_by_id[target_id] || User.select(:id, :updated_at).find(params[:id])
    checks = [[viewer, "User", followed_back_user.id], [followed_back_user, "User", viewer.id]]
    cached = Follows::CheckCached.read_multi(checks)
    cached = Follows::CheckCached.fill_user_misses(checks, cached, [viewer.id, followed_back_user.id])
    following_them_check = Follows::CheckCached.call(viewer, "User", followed_back_user.id, cached)
    following_you_check = Follows::CheckCached.call(followed_back_user, "User", viewer.id, cached)

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
    user_id = session_or_remembered_user_id(validate_salt: false)
    request.session_options[:skip] = true unless remembered_user_restored?
    render(plain: "not-logged-in") && return unless user_id

    ids = params.require(:ids).first(MAX_BULK_FOLLOW_IDS).map(&:to_i)
    is_user_type = params[:followable_type] == "User"
    viewer, users_by_id = load_bulk_show_users(user_id, ids, is_user_type)
    render(plain: "not-logged-in") && return unless viewer

    forward_flags, reverse_flags = compute_bulk_follow_flags(viewer, users_by_id, ids, is_user_type)
    native_json = ForemNative.resolve_bulk_follow_json(viewer.id, is_user_type, ids, forward_flags, reverse_flags)
    render json: native_json || legacy_resolve_bulk_follow(viewer.id, is_user_type, ids, forward_flags, reverse_flags)
  end

  def create
    authorize Follow

    followable_type = params.require(:followable_type).to_s.capitalize
    followable_klass = case followable_type
                       when "Organization", "Tag", "Podcast", "Subforem"
                         followable_type.constantize
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
    Rails.cache.delete("#{current_user.cache_key}-#{current_user.formatted_last_followed_at}/followed_tags")
    # Clear the async_info cache, which contains the list of tags the user is currently following
    Rails.cache.delete("#{current_user.cache_key_with_version}/user-info")
    Rails.cache.delete("#{current_user.cache_key_with_version}/user-info-json-#{RequestStore.store[:subforem_id]}")
  end

  def unfollow(followable, followable_type, need_notification: false)
    user_follow = current_user.stop_following(followable)
    Notification.send_new_follower_notification_without_delay(user_follow, is_read: true) if need_notification

    # Clear the user-follows-user cache async
    Follows::DeleteCached.call(current_user, followable_type, followable.id)

    I18n.t("follows_controller.unfollowed")
  end

  def load_show_viewer(user_id)
    return unless user_id

    viewer = User.select(:id, :updated_at, :encrypted_password).find_by(id: user_id)
    viewer if valid_session_viewer?(viewer)
  end

  def load_bulk_show_users(user_id, ids, is_user_type)
    # Follows::CheckCached only needs the follower's id and updated_at (for its cache key),
    # plus encrypted_password to validate the viewer's session authenticatable_salt.
    if is_user_type && ids.any?
      users_by_id = User.where(id: (ids + [user_id]).uniq)
        .select(:id, :updated_at, :encrypted_password)
        .index_by(&:id)
      viewer = users_by_id[user_id]
      [valid_session_viewer?(viewer) ? viewer : nil, users_by_id]
    else
      viewer = load_show_viewer(user_id)
      [viewer, {}]
    end
  end

  def compute_bulk_follow_flags(viewer, users_by_id, ids, is_user_type)
    followable_type = params[:followable_type]
    checks = ids.flat_map do |id|
      [[viewer, followable_type, id], [users_by_id[id], followable_type, viewer.id]]
    end
    cached = Follows::CheckCached.read_multi(checks)
    cached = Follows::CheckCached.fill_user_misses(checks, cached, users_by_id.keys) if is_user_type

    forward_flags = Array.new(ids.size, false)
    reverse_flags = is_user_type ? Array.new(ids.size, false) : []
    ids.each_with_index do |id, idx|
      next if is_user_type && viewer.id == id

      forward_flags[idx] = Follows::CheckCached.call(viewer, followable_type, id, cached) ? true : false
      next unless is_user_type

      reverse_flags[idx] = Follows::CheckCached.call(users_by_id[id], followable_type, viewer.id, cached) ? true : false
    end
    [forward_flags, reverse_flags]
  end

  def legacy_resolve_bulk_follow(viewer_id, is_user_type, ids, forward_flags, reverse_flags)
    result = {}
    ids.each_with_index do |id, idx|
      result[id] = if is_user_type && viewer_id == id
                     "self"
                   elsif is_user_type
                     if forward_flags[idx] && reverse_flags[idx]
                       "mutual"
                     elsif reverse_flags[idx]
                       "follow-back"
                     else
                       forward_flags[idx].to_s
                     end
                   else
                     forward_flags[idx].to_s
                   end
    end
    result
  end
end
