class Internal::ClassifiedListingsController < Internal::ApplicationController
  include ClassifiedListingsToolkit
  layout "internal"

  def index
    @classified_listings = ClassifiedListing.includes(%i[user organization]).page(params[:page]).order("bumped_at DESC").per(50)
    @classified_listings = @classified_listings.where(category: params[:filter]) if params[:filter].present?
  end

  def edit
    @classified_listing = ClassifiedListing.find(params[:id])
  end

  def update
    @classified_listing = ClassifiedListing.find(params[:id])
    handle_publish_status if listing_params[:published]
    bump_listing if listing_params[:action] == "bump"
    update_listing_details
    clear_listings_cache
    flash[:success] = "Listing updated successfully"
    redirect_to "/internal/listings/#{@classified_listing.id}/edit"
  end

  def destroy
    @classified_listing = ClassifiedListing.find(params[:id])
    @classified_listing.destroy
    flash[:warning] = "'#{@classified_listing.title}' was destroyed successfully"
    redirect_to "/internal/listings"
  end

  private

  def listing_params
    allowed_params = %i[published body_markdown title category tag_list action]
    params.require(:classified_listing).permit(allowed_params)
  end

  def handle_publish_status
    unpublish_listing if listing_params[:published] == "0"
    publish_listing if listing_params[:published] == "1"
  end
end
