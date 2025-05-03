module Api
  module ListingsController
    extend ActiveSupport::Concern

    include Pundit::Authorization

    ATTRIBUTES_FOR_SERIALIZATION = %i[
      id user_id organization_id title slug body_markdown cached_tag_list
      classified_listing_category_id processed_html published created_at
    ].freeze
    private_constant :ATTRIBUTES_FOR_SERIALIZATION

    def index
      render json: []
    end

    def show
      @listing = Listing.select(ATTRIBUTES_FOR_SERIALIZATION).find(params[:id])
      set_surrogate_key_header @listing.record_key if @listing
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

    attr_accessor :user

    alias current_user user
  end
end