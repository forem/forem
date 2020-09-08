class ListingsController < ApplicationController
  include ListingsToolkit
  before_action :check_limit, only: [:create]

  INDEX_JSON_OPTIONS = {
    only: %i[
      title processed_html tag_list category id user_id slug contact_via_connect location
    ],
    include: {
      author: { only: %i[username name], methods: %i[username profile_image_90] },
      user: { only: %i[username], methods: %i[username] }
    }
  }.freeze

  DASHBOARD_JSON_OPTIONS = {
    only: %i[
      title tag_list created_at expires_at bumped_at updated_at category id
      user_id slug organization_id location published
    ],
    include: {
      author: { only: %i[username name], methods: %i[username profile_image_90] }
    }
  }.freeze

  before_action :set_listing, only: %i[edit update destroy]
  before_action :set_cache_control_headers, only: %i[index]
  before_action :raise_suspended, only: %i[new create update]
  before_action :authenticate_user!, only: %i[edit update new dashboard]
  after_action :verify_authorized, only: %i[edit update]

  def index
    published_listings = Listing.where(published: true)
    @displayed_listing = published_listings.find_by(slug: params[:slug]) if params[:slug]

    if params[:view] == "moderate"
      not_found unless @displayed_listing
      return redirect_to edit_admin_listing_path(id: @displayed_listing.id)
    end

    @listings =
      if params[:category].blank?
        published_listings
          .order(bumped_at: :desc)
          .includes(:user, :organization, :taggings)
          .limit(12)
      else
        Listing.none
      end

    @listings_json = @listings.to_json(INDEX_JSON_OPTIONS)
    @displayed_listing_json = @displayed_listing.to_json(INDEX_JSON_OPTIONS)

    # TODO: [mkohl] Can we change this to listings-#{params[:category]}?
    set_surrogate_key_header "classified-listings-#{params[:category]}"
  end

  def new
    @listing = Listing.new
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
    authorize @listing
    @organizations = current_user.organizations
    @credits = current_user.credits.unspent
  end

  def dashboard
    listings = current_user.listings
      .includes(:organization, :taggings)
    @listings_json = listings.to_json(DASHBOARD_JSON_OPTIONS)

    organizations_ids = current_user.organization_memberships
      .where(type_of_user: "admin")
      .pluck(:organization_id)
    orgs = Organization.where(id: organizations_ids)
    @orgs_json = orgs.to_json(only: %i[id name slug unspent_credits_count])
    org_listings = Listing.where(organization_id: organizations_ids)
    @org_listings_json = org_listings.to_json(DASHBOARD_JSON_OPTIONS)
    @user_credits = current_user.unspent_credits_count
  end

  def delete_confirm
    @listing = Listing.find_by(slug: params[:slug])
    not_found unless @listing
    authorize @listing
  end

  def destroy
    authorize @listing
    @listing.destroy!
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
    redirect_to listings_path
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

  def check_limit
    rate_limit!(:listing_creation)
  end
end
