# Included in Application Controller to monkey patch Devise::Controllers::Helpers#current_user
# https://github.com/heartcombo/devise/blob/5d5636f03ac19e8188d99c044d4b5e90124313af/lib/devise/controllers/helpers.rb#L103
module EdgeCacheSafetyCheck
  extend ActiveSupport::Concern

  CANNOT_USE_CURRENT_USER = "You may not use current_user in this cached code path.".freeze

  def current_user
    # In production, current_user will cause a cache leak if it's placed within an edge-cached code path.
    # More information here:
    # https://developers.forem.com/technical-overview/architecture/#we-cache-many-content-pages-on-the-edge
    return super unless RequestStore.store[:edge_caching_in_place]

    return if session_current_user_id.blank?

    CANNOT_USE_CURRENT_USER
  end
end
