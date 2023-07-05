module Api
  module Admin
    module OrganizationsController
      extend ActiveSupport::Concern

      def create
        Organization.create!(organization_params)

        head :ok
      end

      def update
        organization = Organization.find(params[:id])
        organization.update!(organization_params)

        head :ok
      end

      def destroy
        Organization.find(params[:id])&.destroy

        head :ok
      end

      private

      def organization_params
        params.require(:organization).permit %i[name profile_image slug summary tag_line url]
      end
    end
  end
end
