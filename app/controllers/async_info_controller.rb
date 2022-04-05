class AsyncInfoController < ApplicationController
  # No pundit policy. All actions are unrestricted.

  def base_data
    flash.discard(:notice)
    unless user_signed_in?
      render json: {
        broadcast: broadcast_data,
        param: request_forgery_protection_token,
        token: form_authenticity_token
      }
      return
    end
    @user = current_user.decorate
    respond_to do |format|
      format.json do
        render json: {
          broadcast: broadcast_data,
          param: request_forgery_protection_token,
          token: form_authenticity_token,
          user: user_data,
          creator: user_is_a_creator
        }
      end
    end
  end

  def broadcast_data
    broadcast = Broadcast.announcement.active.first.presence
    return unless broadcast

    {
      title: broadcast&.title,
      html: broadcast&.processed_html,
      banner_class: helpers.banner_class(broadcast)
    }.to_json
  end

  # @note The `user_cache_key` uses `current_user` and this method assumes `@user` which is a
  #       decorated version of the user.  It would be nice if we were using the same "variable" for
  #       the cache key and for that which we cache.
  def user_data
    Rails.cache.fetch(user_cache_key, expires_in: 15.minutes) do
      AsyncInfo.to_hash(user: @user, context: self)
    end.to_json
  end

  def user_is_a_creator
    @user.creator?
  end

  def user_cache_key
    "user-info-#{current_user&.id}__
    #{current_user&.last_sign_in_at}__
    #{current_user&.following_tags_count}__
    #{current_user&.last_followed_at}__
    #{current_user&.last_reacted_at}__
    #{current_user&.updated_at}__
    #{current_user&.reactions_count}__
    #{current_user&.articles_count}__
    #{current_user&.blocking_others_count}__"
  end
end
