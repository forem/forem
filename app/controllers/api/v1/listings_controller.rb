module Api
  module V1
    class ListingsController < ApiController
      before_action :authenticate_with_api_key_or_current_user!, only: %i[create update]
      before_action :authenticate_with_api_key_or_current_user, only: %i[show]
      before_action :set_cache_control_headers, only: %i[index show]
      before_action :set_and_authorize_listing, only: %i[update]

      def index
        render json: []
      end

      def show
        render json: {}
      end

      def create
        head :ok
      end

      def update
        head :ok
      end

      def destroy
        head :ok
      end

      private

      def set_and_authorize_listing
        @listing = Listing.find(params[:id])
      end
    end
  end
end