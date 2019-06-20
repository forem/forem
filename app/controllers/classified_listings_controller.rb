class ClassifiedListingsController < ApplicationController
  include ClassifiedListingsToolkit
  before_action :set_classified_listing, only: %i[edit update]
  before_action :set_cache_control_headers, only: %i[index]
  after_action :verify_authorized, only: %i[edit update]
  before_action :authenticate_user!, only: %i[edit update new dashboard]

  def index
    @displayed_classified_listing = ClassifiedListing.find_by!(slug: params[:slug]) if params[:slug]
    mod_page if params[:view] == "moderate"
    @classified_listings = if params[:category].blank?
                             ClassifiedListing.where(published: true).order("bumped_at DESC").limit(12)
                           else
                             []
                           end
    set_surrogate_key_header "classified-listings-#{params[:category]}"
  end

  def new
    @classified_listing = ClassifiedListing.new
    @organizations = current_user.organizations
    @credits = current_user.credits.where(spent: false)
  end

  def edit
    authorize @classified_listing
    @organizations = current_user.organizations
    @credits = current_user.credits.where(spent: false)
  end

  def create
    @classified_listing = ClassifiedListing.new(listing_params)
    @classified_listing.user_id = current_user.id
    @number_of_credits_needed = ClassifiedListing.cost_by_category(@classified_listing.category)
    @org = Organization.find_by(id: @classified_listing.organization_id)
    available_org_credits = @org.credits.where(spent: false) if @org
    available_individual_credits = current_user.credits.where(spent: false)

    if @org && available_org_credits.size >= @number_of_credits_needed
      create_listing(available_org_credits)
    elsif available_individual_credits.size >= @number_of_credits_needed
      create_listing(available_individual_credits)
    else
      redirect_to "/credits"
    end
  end

  def create_listing(credits)
    @classified_listing.bumped_at = Time.current
    @classified_listing.published = true
    # this will 500 for now if they don't belong in the org
    authorize @classified_listing, :authorized_organization_poster? if @classified_listing.organization_id.present?
    if @classified_listing.save
      clear_listings_cache
      credits.limit(@number_of_credits_needed).update_all(spent: true)
      @classified_listing.index!
      redirect_to "/listings"
    else
      @credits = current_user.credits.where(spent: false)
      @classified_listing.cached_tag_list = listing_params[:tag_list]
      @organizations = current_user.organizations
      render :new
    end
  end

  def update
    authorize @classified_listing
    available_credits = current_user.credits.where(spent: false)
    number_of_credits_needed = ClassifiedListing.cost_by_category(@classified_listing.category) # Bumping
    if listing_params[:action] == "bump"
      bump_listing
      if available_credits.size >= number_of_credits_needed
        @classified_listing.save
        available_credits.limit(number_of_credits_needed).update_all(spent: true)
      end
    elsif listing_params[:action] == "unpublish"
      unpublish_listing
    elsif listing_params[:action] == "publish"
      publish_listing
    elsif listing_params[:body_markdown].present? && @classified_listing.bumped_at > 24.hours.ago
      update_listing_details
    end
    clear_listings_cache
    redirect_to "/listings"
  end

  def dashboard
    @classified_listings = current_user.classified_listings
    organizations_ids = current_user.organization_memberships.
      where(type_of_user: "admin").
      pluck(:organization_id)
    @orgs = Organization.where(id: organizations_ids)
    @org_listings = ClassifiedListing.where(organization_id: organizations_ids)
    @user_credits = current_user.unspent_credits_count
  end

  private

  def mod_page
    redirect_to "/internal/listings/#{@displayed_classified_listing.id}/edit"
  end

  def set_classified_listing
    @classified_listing = ClassifiedListing.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow a specific list through.
  def listing_params
    accessible = %i[title body_markdown category tag_list contact_via_connect organization_id action]
    params.require(:classified_listing).permit(accessible)
  end
end
