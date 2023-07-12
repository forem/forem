module Api
  module V1
    class OrganizationsController < ApiController
      include Api::OrganizationsController

      ATTRIBUTES_FOR_SERIALIZATION = %i[
        id name profile_image slug summary tag_line url
      ].freeze

      before_action :find_organization, only: %i[users listings articles]

      def index
        per_page = (params[:per_page] || 30).to_i
        num = [per_page, per_page_max].min
        page = params[:page] || 1

        organizations = Organization.select(ATTRIBUTES_FOR_SERIALIZATION).page(page).per(num)

        render json: organizations
      end

      def show
        organization = Organization.select(SHOW_ATTRIBUTES_FOR_SERIALIZATION)
          .find_by(username: params[:username])
        unless organization&.id
          organization = Organization.select(SHOW_ATTRIBUTES_FOR_SERIALIZATION)
            .find(id: params[:id])
        end

        render json: organization
      end

      def show_by_id
        organization = Organization.select(SHOW_ATTRIBUTES_FOR_SERIALIZATION)
          .find(params[:id])

        render json: organization
      end
    end
  end
end
