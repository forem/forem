class HistoryController < ApplicationController
  before_action :generate_algolia_search_key

  def index
    @history_index = true # used exclusively by the ERb templates
  end

  private

  def generate_algolia_search_key
    params = { filters: "viewable_by:#{current_user.id}" }
    key = ApplicationConfig["ALGOLIASEARCH_SEARCH_ONLY_KEY"]
    @secured_algolia_key = Algolia.generate_secured_api_key(key, params)
  end
end
