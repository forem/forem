class ReadingListItemsController < ApplicationController
  before_action :set_cache_control_headers, only: [:index]

  def index
    @reading_list_items_index = true
    generate_algolia_search_key
    set_surrogate_key_header "reading-list-index"
  end

  def generate_algolia_search_key
    current_user_id = current_user.id
    params = { filters: "viewable_by:#{current_user_id}" }
    @secured_algolia_key = Algolia.generate_secured_api_key(
      ApplicationConfig["ALGOLIASEARCH_SEARCH_ONLY_KEY"], params
    )
  end
end
