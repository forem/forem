module EdgeCacheSafetyCheck
  extend ActiveSupport::Concern

  CANNOT_USE_CURRENT_USER = "You may not use current_user in this cached code path.".freeze

  def current_user
    # In production, current_user will cause a cache leak if it's placed within an edge-cached code path.
    # More information here:
    # https://docs.forem.com/technical-overview/architecture/#we-cache-many-content-pages-on-the-edge
    return super unless RequestStore.store[:edge_caching_in_place]

    return if session_current_user_id.blank?

    CANNOT_USE_CURRENT_USER
  end
end
