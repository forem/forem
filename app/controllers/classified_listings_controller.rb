class ClassifiedListingsController < ApplicationController
  include ClassifiedListingsToolkit

  before_action :set_classified_listing, only: %i[edit update destroy]
  before_action :set_cache_control_headers, only: %i[index]
  before_action :raise_suspended, only: %i[new create update]
  after_action :verify_authorized, only: %i[edit update]
  before_action :authenticate_user!, only: %i[edit update new dashboard]

  def index
    published_listings = ClassifiedListing.where(published: true)
    @displayed_classified_listing = published_listings.find_by(slug: params[:slug]) if params[:slug]

    if params[:view] == "moderate"
      return redirect_to "/internal/listings/#{@displayed_classified_listing.id}/edit"
    end

    @classified_listings = if params[:category].blank?
                             published_listings.
                               order("bumped_at DESC").
                               includes(:user, :organization, :taggings).
                               limit(12)
                           else
                             ClassifiedListing.none
                           end
    set_surrogate_key_header "classified-listings-#{params[:category]}"
  end

  def new
    @classified_listing = ClassifiedListing.new
    @organizations = current_user.organizations
    @credits = current_user.credits.unspent
  end

  def create
    super
  end

  def update
    super
  end

  def edit
    authorize @classified_listing
    @organizations = current_user.organizations
    @credits = current_user.credits.unspent
  end

  def dashboard
    @classified_listings = current_user.classified_listings.
      includes(:organization, :taggings)

    organizations_ids = current_user.organization_memberships.
      where(type_of_user: "admin").
      pluck(:organization_id)
    @orgs = Organization.where(id: organizations_ids)
    @org_listings = ClassifiedListing.where(organization_id: organizations_ids)
    @user_credits = current_user.unspent_credits_count
  end

  def delete_confirm
    @classified_listing = ClassifiedListing.find_by(slug: params[:slug])
    not_found unless @classified_listing
    authorize @classified_listing
  end

  def destroy
    authorize @classified_listing
    @classified_listing.destroy!
    redirect_to "/listings/dashboard", notice: "Listing was successfully deleted."
  end

  private

  def process_no_credit_left
    redirect_to credits_path, notice: "Not enough available credits"
  end

  def process_successful_draft
    redirect_to "/listings/dashboard"
  end

  def process_unsuccessful_draft
    render :new
  end

  def process_successful_creation
    redirect_to classified_listings_path
  end

  def process_unsuccessful_creation
    render :new
  end

  def process_unsuccessful_update
    render :edit
  end

  def process_after_update
    redirect_to "/listings"
  end

  def process_after_unpublish
    redirect_to "/listings/dashboard"
  end
end
