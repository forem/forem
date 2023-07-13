module Api
  module V1
    module Admin
      class OrganizationsController < ApiController
        before_action :authenticate!
        before_action :authorize_super_admin

        def update
          organization = Organization.find(params[:id])
          organization.assign_attributes(organization_params)

          if organization.save
            render json: {
              id: organization.id,
              name: organization.name,
              profile_image: organization.profile_image,
              slug: organization.slug,
              summary: organization.summary,
              tag_line: organization.tag_line,
              url: organization.url
            }, status: :ok
          else
            render json: { error: organization.errors_as_sentence, status: 422 }, status: :unprocessable_entity
          end
        end

        def destroy
          organization = Organization.find(params[:id])
          organization.destroy

          render json: {}, status: :ok
        end

        private

        def organization_params
          params.require(:organization).permit(:name, :profile_image, :slug, :summary, :tag_line, :url)
        end
      end
    end
  end
end
