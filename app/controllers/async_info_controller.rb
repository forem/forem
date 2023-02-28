# @note No pundit policy. All actions are unrestricted.
class AsyncInfoController < ApplicationController
  NUMBER_OF_MINUTES_FOR_CACHE_EXPIRY = 15
  before_action :set_cache_control_headers, only: %i[navigation_links]

  def base_data
    flash.discard(:notice)
    if user_signed_in?
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
    else
      render json: {
        broadcast: broadcast_data,
        param: request_forgery_protection_token,
        token: form_authenticity_token
      }
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
    Rails.cache.fetch("#{current_user.cache_key_with_version}/user-info",
                      expires_in: NUMBER_OF_MINUTES_FOR_CACHE_EXPIRY.minutes) do
      AsyncInfo.to_hash(user: @user, context: self)
    end.to_json
  end

  def user_is_a_creator
    @user.creator?
  end

  def navigation_links
    # We're sending HTML over the wire hence 'render layout: false' enforces rails NOT TO look for a layout file to wrap
    # the view file - it allows us to not include the HTML headers for sending back to client.
    render layout: false
  end
end
