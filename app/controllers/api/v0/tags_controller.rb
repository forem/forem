module Api
  module V0
    class TagsController < ApplicationController
      respond_to :json

      before_action :set_cache_control_headers, only: %i[index onboarding]

      def index
        page = params[:page]
        per_page = (params[:per_page] || 10).to_i
        num = [per_page, 1000].min

        @tags = Tag.order(taggings_count: :desc).page(page).per(num)

        set_surrogate_key_header Tag.table_key, @tags.map(&:record_key)
      end

      def onboarding
        @tags = Tag.where(name: SiteConfig.suggested_tags)

        set_surrogate_key_header Tag.table_key, @tags.map(&:record_key)
      end
    end
  end
end
