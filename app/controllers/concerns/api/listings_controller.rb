module Api
  module ListingsController
    extend ActiveSupport::Concern

    include Pundit::Authorization
    include ListingsToolkit

    # NOTE: since this is used for selecting from the DB, we need to use the
    # actual column name for the listing category, prefixed with classified_.
    ATTRIBUTES_FOR_SERIALIZATION = %i[
      id user_id organization_id title slug body_markdown cached_tag_list
      classified_listing_category_id processed_html published created_at
    ].freeze
    private_constant :ATTRIBUTES_FOR_SERIALIZATION

    def index
      @listings = Listing.published
        .select(ATTRIBUTES_FOR_SERIALIZATION)
        .includes([{ user: :profile }, :organization, :taggings, :listing_category])

      if params[:category].present?
        @listings = @listings.in_category(params[:category])
      end
      @listings = @listings.order(bumped_at: :desc)

      per_page = (params[:per_page] || 30).to_i
      per_page_max = (ApplicationConfig["API_PER_PAGE_MAX"] || 100).to_i
      num = [per_page, per_page_max].min
      page = params[:page] || 1
      @listings = @listings.page(page).per(num)

      set_surrogate_key_header Listing.table_key, @listings.map(&:record_key)
    end

    def show
      relation = Listing.published

      # if the user is authenticated we allow them to access
      # their own unpublished listings as well
      relation = relation.union(@user.listings) if @user

      @listing = relation.select(ATTRIBUTES_FOR_SERIALIZATION).find(params[:id])

      set_surrogate_key_header @listing.record_key
    end

    private

    attr_accessor :user

    alias current_user user

    def process_no_credit_left
      msg = I18n.t("api.v0.listings_controller.no_credit")
      render json: { error: msg, status: 402 }, status: :payment_required
    end

    def process_successful_draft
      render "show", status: :created
    end

    def process_unsuccessful_draft
      render json: { errors: @listing.errors }, status: :unprocessable_entity
    end

    def process_successful_creation
      render "show", status: :created
    end

    def process_unsuccessful_creation
      render json: { errors: @listing.errors }, status: :unprocessable_entity
    end

    alias process_unsuccessful_update process_unsuccessful_creation

    def process_after_update
      render "show", status: :ok
    end

    def process_after_unpublish
      render "show", status: :ok
    end

    # Since our documentation examples now use "listing", prefer that,
    # but permit the legacy parameter "classified_listing",
    # since this was a published API before the refactoring renamed
    # ClassifiedListing to Listing in https://github.com/forem/forem/pull/7910
    def listing_params
      params["listing"] ||= params["classified_listing"]
      if (category_id = find_category_id(params.dig("listing", "category")))
        params["listing"]["listing_category_id"] = category_id
      end
      super
    end

    def find_category_id(slug)
      return if slug.blank?

      ListingCategory.select(:id).find_by(slug: slug)&.id
    end
  end
end
