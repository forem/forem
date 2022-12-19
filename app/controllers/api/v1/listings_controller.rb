module Api
  module V1
    class ListingsController < ApiController
      include Api::ListingsController

      # actions `create` and `update` are defined in the module `ListingsToolkit`,
      # we thus silence Rubocop lexical scope filter cop: https://rails.rubystyle.guide/#lexically-scoped-action-filter
      before_action :authenticate_with_api_key_or_current_user!, only: %i[create update]
      before_action :authenticate_with_api_key_or_current_user, only: %i[show]
      before_action :set_cache_control_headers, only: %i[index show]
      before_action :set_and_authorize_listing, only: %i[update]
    end
  end
end
