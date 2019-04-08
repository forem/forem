module Api
  module V0
    class TagsController < ApplicationController
      # before_action :set_cache_control_headers, only: [:index]
      caches_action :index,
                    cache_path: proc { |c| c.params.permit! },
                    expires_in: 10.minutes
      respond_to :json

      def index
        @page = params[:page]
        @tags = Tag.order(taggings_count: :desc).page(@page).per(10)
      end

      def onboarding
        @tags = Tag.where(name: Tag::NAMES)
      end
    end
  end
end
