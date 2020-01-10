module Api
  module V0
    class TagsController < ApplicationController
      caches_action :index,
                    cache_path: proc { |c| c.params.permit! },
                    expires_in: 10.minutes
      before_action :set_cache_control_headers, only: %i[onboarding] # essentially static content
      respond_to :json

      def index
        @page = params[:page]
        @tags = Tag.order(taggings_count: :desc).page(@page).per(10)
      end

      def onboarding
        set_surrogate_key_header "siteconfig/onboarding-tags"
        @tags = Tag.where(name: SiteConfig.suggested_tags)
      end
    end
  end
end
