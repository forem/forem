class OpenSearchController < ApplicationController
  before_action :set_cache_control_headers, only: %i[show]

  def show
    set_surrogate_key_header "open-search-xml"
    render layout: false
  end
end
