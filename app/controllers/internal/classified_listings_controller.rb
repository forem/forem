class Internal::ClassifiedListingsController < Internal::ApplicationController
  include ClassifiedListingsToolkit
  layout "internal"

  def index
    @classified_listings =
      ClassifiedListing.includes(%i[user classified_listing_category]).
        page(params[:page]).order("bumped_at DESC").per(50)

    @classified_listings = @classified_listings.published unless include_unpublished?
    @classified_listings = @classified_listings.in_category(params[:filter]) if params[:filter].present?
  end

  def edit
    @classified_listing = ClassifiedListing.find(params[:id])
  end

  def update
    @classified_listing = ClassifiedListing.find(params[:id])
    handle_publish_status if listing_params[:published]
    bump_listing(@classified_listing.cost) if listing_params[:action] == "bump"
    update_listing_details
    clear_listings_cache
    flash[:success] = "Listing updated successfully"
    redirect_to edit_internal_classified_listing_path(@classified_listing)
  end

  def destroy
    @classified_listing = ClassifiedListing.find(params[:id])
    @classified_listing.destroy
    flash[:warning] = "'#{@classified_listing.title}' was destroyed successfully"
    redirect_to internal_classified_listings_path
  end

  private

  ALLOWED_PARAMS = %i[
    published body_markdown title category classified_listing_category_id tag_list action
  ].freeze
  private_constant :ALLOWED_PARAMS

  def listing_params
    params.require(:classified_listing).permit(ALLOWED_PARAMS)
  end

  def handle_publish_status
    unpublish_listing if listing_params[:published] == "0"
    publish_listing if listing_params[:published] == "1"
  end

  def include_unpublished?
    params[:include_unpublished] == "1"
  end
end
