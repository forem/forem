module Api
  module V1
    class OrganizationsController < ApiController
      include Api::OrganizationsController

      ATTRIBUTES_FOR_SERIALIZATION = %i[
        id name profile_image slug summary tag_line url
      ].freeze
      private_constant ATTRIBUTES_FOR_SERIALIZATION

      before_action :find_organization, only: %i[users listings articles]

      def index
        per_page = (params[:per_page] || 30).to_i
        num = [per_page, per_page_max].min
        page = params[:page] || 1

        @organization = Organization.select(ATTRIBUTES_FOR_SERIALIZATION).page(page).per(num)
      end

      def show
        @organization = Organization.select(SHOW_ATTRIBUTES_FOR_SERIALIZATION)
          .find_by!(username: params[:username])
      end
    end
  end
end
