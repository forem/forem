class ClassifiedListingsController < ApplicationController
  before_action :set_classified_listing, only: [:show, :edit, :update, :destroy]
  before_action :set_cache_control_headers, only: %i[index]

  # GET /classified_listings
  # GET /classified_listings.json
  def index
    @classified_listings = ClassifiedListing.order("created_at DESC")
    if params[:category]
      @classified_listings = @classified_listings.where(category: params[:category])
    end
    if params[:tag]
      @classified_listings = @classified_listings.tagged_with(params[:tag])
    end
    set_surrogate_key_header "classified-listings-#{params[:category]}-#{params[:tag]}"
  end

  # GET /classified_listings/1
  # GET /classified_listings/1.json
  def show
  end

  # GET /classified_listings/new
  def new
    @classified_listing = ClassifiedListing.new
    @credits = current_user.credits.where(spent: false)
  end

  # GET /classified_listings/1/edit
  def edit
  end

  # POST /classified_listings
  # POST /classified_listings.json
  def create
    @classified_listing = ClassifiedListing.new(classified_listing_params)
    @classified_listing.user_id = current_user.id
    number_of_credits_needed = ClassifiedListing.cost_by_category(@classified_listing.category)
    available_credits = current_user.credits.where(spent: false)
    if available_credits.size >= number_of_credits_needed
      @classified_listing.save!
      available_credits.limit(number_of_credits_needed).update_all(spent: true)
      CacheBuster.new.bust("/listings")
      CacheBuster.new.bust("/listings?i=i")
      CacheBuster.new.bust("/listings/#{@classified_listing.category}")
      CacheBuster.new.bust("/listings/#{@classified_listing.category}?i=i")
      redirect_to "/listings"
    else
      raise "Not enough credits"
      render :new
    end
  end

  # PATCH/PUT /classified_listings/1
  # PATCH/PUT /classified_listings/1.json
  def update
    respond_to do |format|
      if @classified_listing.update(classified_listing_params)
        format.html { redirect_to @classified_listing, notice: 'Classified listing was successfully updated.' }
        format.json { render :show, status: :ok, location: @classified_listing }
      else
        format.html { render :edit }
        format.json { render json: @classified_listing.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /classified_listings/1
  # DELETE /classified_listings/1.json
  def destroy
    @classified_listing.destroy
    respond_to do |format|
      format.html { redirect_to classified_listings_url, notice: 'Classified listing was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_classified_listing
      @classified_listing = ClassifiedListing.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def classified_listing_params
      accessible = %i[title body_markdown category tag_list]
      params.require(:classified_listing).permit(accessible)
    end
end
