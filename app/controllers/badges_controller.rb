class BadgesController < ApplicationController
  before_action :set_cache_control_headers, only: [:show]
  def show
    @badge = Badge.find_by_slug(params[:slug])
    set_surrogate_key_header "badges-show-action"
  end
end
