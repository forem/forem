module EdgeCacheSafetyCheck
  extend ActiveSupport::Concern

  CANNOT_USE_CURRENT_USER = "You may not use current_user in this cached code path.".freeze

  def current_user
    # In production, using current_user in a view which will be cached will result in a cache leak.
    # https://docs.forem.com/technical-overview/architecture/#we-cache-many-content-pages-on-the-edge
    return super unless @edge_caching_in_place

    return if session_current_user_id.blank?

    @current_user_called_erroneously = true

    CANNOT_USE_CURRENT_USER
  end
end
