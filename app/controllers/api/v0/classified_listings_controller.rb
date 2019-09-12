module Api
  module V0
    class ClassifiedListingsController < ApiController
      include ClassifiedListingsToolkit
      respond_to :json

      before_action :set_classified_listing, only: %i[show update]
      before_action :authenticate!, only: %i[create update]

      # skip CSRF checks for create and update
      skip_before_action :verify_authenticity_token, only: %i[create update]

      def index
        @classified_listings = ClassifiedListing.published.
          order("bumped_at DESC").
          includes(:user, :organization, :taggings)

        @classified_listings = if params[:category].present?
                                 @classified_listings.where(category: params[:category])
                               else
                                 @classified_listings.limit(12)
                               end

        set_surrogate_key_header "classified-listings-#{params[:category]}"
      end

      def show
        # rendering with json builder
      end

      def create
        super
      end

      def update
        super
      end

      private

      attr_accessor :user

      alias current_user user

      def process_no_credit_left
        msg = "Not enough available credits"
        render json: [{ error: msg }], status: :payment_required
      end

      def process_successful_draft
        json_response(@classified_listing, :created)
      end

      def process_unsuccessful_draft
        render json: [{ error: @classified_listing.errors }], status: :unprocessable_entity
      end

      def process_successful_creation
        json_response(@classified_listing, :created)
      end

      def process_unsuccessful_creation
        render json: [{ error: @classified_listing.errors }], status: :unprocessable_entity
      end

      def json_response(object, status = :ok)
        render json: object, status: status
      end

      def process_after_update
        json_response(@classified_listing, :ok)
      end

      def process_after_unpublish
        json_response(@classified_listing, :ok)
      end
    end
  end
end
