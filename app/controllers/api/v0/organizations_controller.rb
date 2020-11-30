module Api
  module V0
    class OrganizationsController < ApiController
      before_action :find_organization, only: %i[users]

      SHOW_ATTRIBUTES_FOR_SERIALIZATION = %i[
        username name summary twitter_username github_username url
        location created_at profile_image tech_stack tag_line story
      ].freeze
      private_constant :SHOW_ATTRIBUTES_FOR_SERIALIZATION

      USERS_FOR_SERIALIZATION = %i[
        id username name twitter_username github_username
        profile_image website_url location summary created_at
      ].freeze
      private_constant :USERS_FOR_SERIALIZATION

      def show
        @organization = Organization.select(SHOW_ATTRIBUTES_FOR_SERIALIZATION)
          .find_by!(username: params[:username])
      end

      def users
        per_page = (params[:per_page] || 30).to_i
        num = [per_page, 1000].min
        page = params[:page] || 1

        @users = @organization.users.select(USERS_FOR_SERIALIZATION).page(page).per(num)
      end

      private

      def find_organization
        @organization = Organization.find_by!(username: params[:organization_username])
      end
    end
  end
end
