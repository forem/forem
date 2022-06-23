module Api
  module V0
    # @note This controller partially authorizes with the ArticlePolicy, in an ideal world, it would
    #       fully authorize.  However, that refactor would require significantly more work.
    class ArticlesController < ApiController
      include Api::ArticlesController

      before_action :authenticate!, only: %i[create update me]

      before_action :validate_article_param_is_hash, only: %i[create update]

      before_action :set_cache_control_headers, only: %i[index show show_by_slug]

      skip_before_action :verify_authenticity_token, only: %i[create update]

      after_action :verify_authorized, only: %i[create]
    end
  end
end
