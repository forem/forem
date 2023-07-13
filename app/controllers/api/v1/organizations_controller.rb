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
        # This borrows from the existing "show by username" route to add id lookup as a first step.
        # The reason is that we want people to access both api/organizations/:username (old style)
        # as well as api/organizations/:id ("new" style)
        # Ultimately it might be best to rename the less restful "by username" lookup to a different
        organization = Organization
          .select(SHOW_ATTRIBUTES_FOR_SERIALIZATION)
          .find_by(id: params[:username].to_i)
        # If we can't find the organization by id, we'll use the username
        unless organization&.id
          organization = Organization
            .select(SHOW_ATTRIBUTES_FOR_SERIALIZATION)
            .find_by(username: params[:username])
        end

        render json: organization, status: organization ? :ok : :not_found
      end
    end
  end
end
