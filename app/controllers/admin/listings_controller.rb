module Admin
  class ListingsController < Admin::ApplicationController
    include ListingsToolkit
    ALLOWED_PARAMS = %i[
      published body_markdown title category listing_category_id tag_list action organization_id
    ].freeze
    layout "admin"

    def index
      @listings =
        Listing.includes(%i[user listing_category])
          .page(params[:page]).order(bumped_at: :desc).per(50)

      @listings = @listings.published unless include_unpublished?
      @listings = @listings.in_category(params[:filter]) if params[:filter].present?
    end

    def edit
      @listing = Listing.find(params[:id])
    end

    def update
      @listing = Listing.find(params[:id])
      handle_publish_status if listing_params[:published]
      bump_listing(@listing.cost) if listing_params[:action] == "bump"
      update_listing_details
      clear_listings_cache
      flash[:success] = "Listing updated successfully"
      redirect_to edit_admin_listing_path(@listing)
    end

    def destroy
      @listing = Listing.find(params[:id])
      @listing.destroy
      flash[:warning] = "'#{@listing.title}' was destroyed successfully"
      redirect_to admin_listings_path
    end

    private

    private_constant :ALLOWED_PARAMS

    def listing_params
      params.require(:listing).permit(ALLOWED_PARAMS)
    end

    def handle_publish_status
      unpublish_listing if listing_params[:published] == "0"
      publish_listing if listing_params[:published] == "1"
    end

    def include_unpublished?
      params[:include_unpublished] == "1"
    end
  end
end
