class FeedConfigVisitsController < ApplicationMetalController
  prepend_before_action :current_user_by_token, only: [:create]
  skip_forgery_protection if: :token_authenticated?
  include ActionController::Head

  REQUESTS_PER_MINUTE = 60

  def create
    response.headers["Cache-Control"] = "private, no-store"
    return head :no_content unless session_current_user_id
    return head :no_content if FeatureFlag.enabled?(:disable_browser_feed_events)

    if Rack::Attack.cache.count("feed_config_visits/user/#{session_current_user_id}", 60) > REQUESTS_PER_MINUTE
      response.headers["Retry-After"] = "60"
      return head :too_many_requests
    end
    return head :bad_request unless params[:visit_token].is_a?(String) && params[:visit_token].bytesize <= 4096 &&
      params[:event_id].is_a?(String) && Feeds::RecordConfigVisit::UUID_PATTERN.match?(params[:event_id])

    next_visit_at = Feeds::RecordConfigVisit.call(
      token: params[:visit_token], event_id: params[:event_id], user_id: session_current_user_id, host: request.host,
    )
    return head :no_content unless next_visit_at

    response.headers["X-Feed-Visit-Wait"] = [next_visit_at - Time.current, 0].max.ceil.to_s
    head :ok
  end
end
