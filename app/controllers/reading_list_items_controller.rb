class ReadingListItemsController < ApplicationController
  before_action :set_cache_control_headers, only: [:index]

  def index
    @reading_list_items_index = true
    set_surrogate_key_header "reading-list-index"
  end
end
