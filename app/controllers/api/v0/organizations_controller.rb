module Api
  module V0
    class OrganizationsController < ApiController
      SHOW_ATTRIBUTES_FOR_SERIALIZATION = %i[
        username name summary twitter_username github_username url
        location created_at profile_image tech_stack tag_line story
      ].freeze
      private_constant :SHOW_ATTRIBUTES_FOR_SERIALIZATION

      def show
        @organization = Organization.select(SHOW_ATTRIBUTES_FOR_SERIALIZATION)
          .find_by!(username: params[:org_username])
      end
    end
  end
end
