module Api
  module V0
    class TagsController < ApplicationController
      # before_action :set_cache_control_headers, only: [:index]
      caches_action :index,
        cache_path: Proc.new { |c| c.params.permit! },
        expires_in: 10.minutes
      respond_to :json

      def index
        @page = params[:page]
        @tags = Tag.all.order("taggings_count DESC").page(@page).per(10)
      end

      def onboarding
        # Andy: Alphabetized by names
        tag_names = %w[
          beginners
          career
          computerscience
          git
          go
          java
          javascript
          linux
          productivity
          python
          security
          webdev
        ]
        @tags = []
        tag_names.each do |tag_name|
          @tags.push(Tag.find_by(name: tag_name))
        end
        @tags = @tags.reject(&:nil?)
      end
    end
  end
end
