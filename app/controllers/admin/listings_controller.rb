module Admin
  class ListingsController < Admin::ApplicationController
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

      if listing_params[:action] == "bump"
        bump_success = Listings::Bump.call(@listing, user: current_user)
        return process_no_credit_left unless bump_success
      end

      @listing.update(listing_params.compact)
      @listing.clear_cache
      flash[:success] = I18n.t("admin.listings_controller.updated")
      redirect_to edit_admin_listing_path(@listing)
    end

    def destroy
      @listing = Listing.find(params[:id])
      @listing.destroy
      flash[:warning] = I18n.t("admin.listings_controller.destroyed", title: @listing.title)
      redirect_to admin_listings_path
    end

    private

    private_constant :ALLOWED_PARAMS

    def listing_params
      params.require(:listing).permit(ALLOWED_PARAMS)
    end

    def handle_publish_status
      @listing.unpublish if listing_params[:published] == "0"
      @listing.publish if listing_params[:published] == "1"
    end

    def include_unpublished?
      params[:include_unpublished] == "1"
    end

    def process_no_credit_left
      redirect_to admin_listings_path, notice: I18n.t("admin.listings_controller.no_credit")
    end
  end
end
