class SidebarsController < ApplicationController
  layout false
  before_action :set_cache_control_headers, only: %i[show]

  def show
    set_surrogate_key_header "home-sidebar"
  end
end
