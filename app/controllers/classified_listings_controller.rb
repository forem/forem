class ClassifiedListingsController < ApplicationController
  include ClassifiedListingsToolkit
  before_action :set_classified_listing, only: %i[edit update]
  before_action :set_cache_control_headers, only: %i[index]
  after_action :verify_authorized, only: %i[edit update]
  before_action :authenticate_user!, only: %i[edit update new dashboard]

  def index
    @displayed_classified_listing = ClassifiedListing.find_by!(slug: params[:slug]) if params[:slug]

    if params[:view] == "moderate"
      return redirect_to "/internal/listings/#{@displayed_classified_listing.id}/edit"
    end

    @classified_listings = if params[:category].blank?
                             ClassifiedListing.where(published: true).
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

  def edit
    authorize @classified_listing
    @organizations = current_user.organizations
    @credits = current_user.credits.unspent
  end

  def create
    @classified_listing = ClassifiedListing.new(listing_params)

    # this will 500 for now if they don't belong in the org
    authorize @classified_listing, :authorized_organization_poster? if @classified_listing.organization_id.present?

    @classified_listing.user_id = current_user.id
    cost = ClassifiedListing.cost_by_category(@classified_listing.category)

    org = Organization.find_by(id: @classified_listing.organization_id)

    available_org_credits = org.credits.unspent if org
    available_user_credits = current_user.credits.unspent

    # we use the org's credits if available, otherwise we default to the user's
    if org && available_org_credits.size >= cost
      create_listing(org, cost)
    elsif available_user_credits.size >= cost
      create_listing(current_user, cost)
    else
      redirect_to credits_path, notice: "Not enough available credits"
    end
  end

  def update
    authorize @classified_listing

    # NOTE: this should probably be split in three different actions: bump, unpublish, publish
    if listing_params[:action] == "bump"
      cost = ClassifiedListing.cost_by_category(@classified_listing.category)

      org = Organization.find_by(id: @classified_listing.organization_id)

      available_org_credits = org.credits.unspent if org
      available_user_credits = current_user.credits.unspent

      if org && available_org_credits.size >= cost
        charge_credits_before_bump(org, cost)
      elsif available_user_credits.size >= cost
        charge_credits_before_bump(current_user, cost)
      else
        redirect_to(credits_path, notice: "Not enough available credits") && return
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
    @classified_listings = current_user.classified_listings.
      includes(:organization, :taggings)

    organizations_ids = current_user.organization_memberships.
      where(type_of_user: "admin").
      pluck(:organization_id)
    @orgs = Organization.where(id: organizations_ids)
    @org_listings = ClassifiedListing.where(organization_id: organizations_ids)
    @user_credits = current_user.unspent_credits_count
  end

  private

  def create_listing(purchaser, cost)
    successful_transaction = false
    ActiveRecord::Base.transaction do
      # subtract credits
      Credits::Buyer.call(
        purchaser: purchaser,
        purchase: @classified_listing,
        cost: cost,
      )

      # save the listing
      @classified_listing.bumped_at = Time.current
      @classified_listing.published = true

      # since we can't raise active record errors in this transaction
      # due to the fact that we need to display them in the :new view,
      # we manually rollback the transaction if there are validation errors
      raise ActiveRecord::Rollback unless @classified_listing.save

      successful_transaction = true
    end

    if successful_transaction
      clear_listings_cache
      @classified_listing.index!
      redirect_to classified_listings_path
    else
      @credits = current_user.credits.unspent
      @classified_listing.cached_tag_list = listing_params[:tag_list]
      @organizations = current_user.organizations
      render :new
    end
  end

  def charge_credits_before_bump(purchaser, cost)
    ActiveRecord::Base.transaction do
      Credits::Buyer.call(
        purchaser: purchaser,
        purchase: @classified_listing,
        cost: cost,
      )

      raise ActiveRecord::Rollback unless bump_listing
    end
  end

  def set_classified_listing
    @classified_listing = ClassifiedListing.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow a specific list through.
  def listing_params
    accessible = %i[title body_markdown category tag_list contact_via_connect location organization_id action]
    params.require(:classified_listing).permit(accessible)
  end
end
