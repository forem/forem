module Api
  module Admin
    module OrganizationsController
      extend ActiveSupport::Concern

      def create
        Organization.create!(organization_params)

        head :ok
      end

      private

      def organization_params
        params.require(:organization).permit[:name, :profile_image, :slug, :summary, :tag_line, :url]
      end
    end
  end
end
