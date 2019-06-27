class ReadingListItemsController < ApplicationController
  def index
    @reading_list_items_index = true
    set_view
    generate_algolia_search_key
  end

  def update
    @reaction = Reaction.find(params[:id])
    raise if @reaction.user_id != current_user.id # Lazy but I'm tired. HACK

    @reaction.status = params[:current_status] == "archived" ? "valid" : "archived"
    @reaction.save
    head :ok
  end

  private

  def generate_algolia_search_key
    params = { filters: "viewable_by:#{current_user.id}" }
    @secured_algolia_key = Algolia.generate_secured_api_key(
      ApplicationConfig["ALGOLIASEARCH_SEARCH_ONLY_KEY"], params
    )
  end

  def set_view
    @view = if params[:view] == "archive"
              "archived"
            else
              "valid"
            end
  end
end
