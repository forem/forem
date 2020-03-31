module Api
  module V0
    class ClassifiedListingsController < ApiController
      include Pundit
      include ClassifiedListingsToolkit

      before_action :authenticate_with_api_key_or_current_user!, only: %i[create update]
      before_action :authenticate_with_api_key_or_current_user, only: %i[show]

      before_action :set_classified_listing, only: %i[update]

      before_action :set_cache_control_headers, only: %i[index show]

      skip_before_action :verify_authenticity_token, only: %i[create update]

      def index
        @classified_listings = ClassifiedListing.published.
          select(ATTRIBUTES_FOR_SERIALIZATION).
          includes(:user, :organization, :taggings)

        @classified_listings = @classified_listings.where(category: params[:category]) if params[:category].present?

        @classified_listings = @classified_listings.order(bumped_at: :desc)

        per_page = (params[:per_page] || 30).to_i
        num = [per_page, 100].min
        page = params[:page] || 1
        @classified_listings = @classified_listings.page(page).per(num)

        set_surrogate_key_header ClassifiedListing.table_key, @classified_listings.map(&:record_key)
      end

      def show
        relation = ClassifiedListing.published

        # if the user is authenticated we allow them to access
        # their own unpublished listings as well
        relation = relation.union(@user.classified_listings) if @user

        @classified_listing = relation.select(ATTRIBUTES_FOR_SERIALIZATION).find(params[:id])

        set_surrogate_key_header @classified_listing.record_key
      end

      def create
        super
      end

      def update
        super
      end

      ATTRIBUTES_FOR_SERIALIZATION = %i[
        id user_id organization_id title slug body_markdown
        cached_tag_list category processed_html published
      ].freeze
      private_constant :ATTRIBUTES_FOR_SERIALIZATION

      private

      attr_accessor :user

      alias current_user user

      def process_no_credit_left
        msg = "Not enough available credits"
        render json: { error: msg, status: 402 }, status: :payment_required
      end

      def process_successful_draft
        render "show", status: :created
      end

      def process_unsuccessful_draft
        render json: { errors: @classified_listing.errors }, status: :unprocessable_entity
      end

      def process_successful_creation
        render "show", status: :created
      end

      def process_unsuccessful_creation
        render json: { errors: @classified_listing.errors }, status: :unprocessable_entity
      end

      alias process_unsuccessful_update process_unsuccessful_creation

      def process_after_update
        render "show", status: :ok
      end

      def process_after_unpublish
        render "show", status: :ok
      end
    end
  end
end
