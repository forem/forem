class ClassifiedListingsController < ApplicationController
  include ClassifiedListingsToolkit
  before_action :set_classified_listing, only: %i[edit update destroy]
  before_action :set_cache_control_headers, only: %i[index]
  before_action :raise_banned, only: %i[new create update]
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

    if listing_params[:action] == "draft"
      @classified_listing.published = false
      if @classified_listing.save
        redirect_to "/listings/dashboard"
      else
        @credits = current_user.credits.unspent
        @classified_listing.cached_tag_list = listing_params[:tag_list]
        @organizations = current_user.organizations
        render :new
      end
      return
    end

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

    cost = ClassifiedListing.cost_by_category(@classified_listing.category)

    # NOTE: this should probably be split in three different actions: bump, unpublish, publish
    return bump_listing(cost) if listing_params[:action] == "bump"

    if listing_params[:action] == "unpublish"
      unpublish_listing
      redirect_to "/listings/dashboard"
      return
    elsif listing_params[:action] == "publish"
      unless @classified_listing.bumped_at?
        first_publish(cost)
        return
      end

      publish_listing
    elsif listing_params[:body_markdown].present? && ((@classified_listing.bumped_at && @classified_listing.bumped_at > 24.hours.ago) || !@classified_listing.published)
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

  def delete_confirm
    @classified_listing = ClassifiedListing.find_by(slug: params[:slug])
    authorize @classified_listing
  end

  def destroy
    authorize @classified_listing
    @classified_listing.destroy!
    redirect_to "/listings/dashboard", notice: "Listing was successfully deleted."
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

  def first_publish(cost)
    available_author_credits = @classified_listing.author.credits.unspent
    available_user_credits = []
    if @classified_listing.author.is_a?(Organization)
      available_user_credits = current_user.credits.unspent
    end

    if available_author_credits.size >= cost
      create_listing(@classified_listing.author, cost)
    elsif available_user_credits.size >= cost
      create_listing(current_user, cost)
    else
      redirect_to credits_path, notice: "Not enough available credits"
    end
  end

  def bump_listing(cost)
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
  end

  def charge_credits_before_bump(purchaser, cost)
    ActiveRecord::Base.transaction do
      Credits::Buyer.call(
        purchaser: purchaser,
        purchase: @classified_listing,
        cost: cost,
      )

      raise ActiveRecord::Rollback unless bump_listing_success
    end
  end

  def set_classified_listing
    @classified_listing = ClassifiedListing.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow a specific list through.
  def listing_params
    accessible = %i[title body_markdown category tag_list expires_at contact_via_connect location organization_id action]
    params.require(:classified_listing).permit(accessible)
  end
end
