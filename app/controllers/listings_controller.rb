class ListingsController < ApplicationController
  include ListingsToolkit

  INDEX_JSON_OPTIONS = {
    only: %i[
      title processed_html tag_list category id user_id slug contact_via_connect location bumped_at
      originally_published_at
    ],
    methods: %i[category],
    include: {
      author: { only: %i[username name], methods: %i[username profile_image_90] },
      user: { only: %i[username], methods: %i[username] }
    }
  }.freeze

  DASHBOARD_JSON_OPTIONS = {
    only: %i[
      title tag_list created_at expires_at bumped_at updated_at id
      user_id slug organization_id location published
    ],
    methods: %i[category],
    include: {
      author: { only: %i[username name], methods: %i[username profile_image_90] }
    }
  }.freeze

  # actions `create` and `update` are defined in the module `ListingsToolkit`,
  # we thus silence Rubocop lexical scope filter cop: https://rails.rubystyle.guide/#lexically-scoped-action-filter
  # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :check_limit, only: [:create]
  before_action :set_listing, only: %i[edit update destroy]
  before_action :set_cache_control_headers, only: %i[index]
  before_action :raise_suspended, only: %i[new create update]
  before_action :authenticate_user!, only: %i[edit update new dashboard]
  after_action :verify_authorized, only: %i[edit update]
  # rubocop:enable Rails/LexicallyScopedActionFilter

  def index
    @displayed_listing = Listing.where(published: true).find_by(slug: params[:slug]) if params[:slug]

    if params[:view] == "moderate"
      not_found unless @displayed_listing
      return redirect_to edit_admin_listing_path(id: @displayed_listing.id)
    end

    @listings =
      if params[:category].blank?
        listings_for_index_view
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

  def edit
    authorize @listing
    @organizations = current_user.organizations
    @credits = current_user.credits.unspent
  end

  def dashboard
    listings = current_user.listings
      .includes(:organization, :taggings, :listing_category)
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
    # The following sets variables used in the index view. We render the
    # index view directly to avoid having to redirect.
    #
    # Redirects lead to a race condition where we redirect to a cached view
    # after updating data and we don't bust the cache fast enough before
    # hitting the view, therefore stale content ends up being served from
    # cache.
    #
    # https://github.com/forem/forem/issues/10338#issuecomment-693401481
    @listings = listings_for_index_view
    @listings_json = @listings.to_json(INDEX_JSON_OPTIONS)

    render :index
  end

  def process_after_unpublish
    redirect_to "/listings/dashboard"
  end

  def check_limit
    rate_limit!(:listing_creation)
  end

  # This is a convenience method to query listings for use in the index view in
  # the index action and process_after_update method
  def listings_for_index_view
    Listing.where(published: true)
      .order(bumped_at: :desc)
      .includes(:user, :organization, :taggings, :listing_category)
      .limit(12)
  end
end
