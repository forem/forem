class ReadingListItemsController < ApplicationController
  before_action :set_cache_control_headers, only: [:index]
  skip_before_action :ensure_signup_complete
  def index
    @reading_list_items_index = true
    set_surrogate_key_header "reading-list-index"
  end
end
