class BadgesController < ApplicationController
  before_action :set_cache_control_headers, only: [:show]
  # No authorization required for entirely public controller

  def show
    @badge = Badge.find_by(slug: params[:slug]) || not_found
    set_surrogate_key_header "badges-show-action"
  end
end
