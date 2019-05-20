class Internal::ClassifiedListingsController < Internal::ApplicationController
  layout "internal"

  def index
    @classified_listings = ClassifiedListing.all
  end

  def edit
    @classified_listing = ClassifiedListing.find(params[:id])
  end

  def update
    @classified_listing = ClassifiedListing.find(params[:id])
    @classified_listing.update!(listing_params)
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
    allowed_params = %i[published body_markdown title category tag_list]
    params.require(:classified_listing).permit(allowed_params)
  end
end
