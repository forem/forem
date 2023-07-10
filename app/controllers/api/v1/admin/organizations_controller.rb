module Api
  module V1
    module Admin
      class OrganizationsController < ApiController
        before_action :authenticate!
        before_action :authorize_super_admin

        def create
          organization = Organization.new organization_params

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
            render json: { error: result.errors_as_sentence, status: 422 }, status: :unprocessable_entity
          end
        end

        def update
          organization = Organization.find(params[:id])
          updated_org = organization.assign_attributes(organization_params)

          if updated_org.save
            render json: {
              id: updated_org.id,
              name: updated_org.name,
              profile_image: updated_org.profile_image,
              slug: updated_org.slug,
              summary: updated_org.summary,
              tag_line: updated_org.tag_line,
              url: updated_org.url
            }, status: :ok
          else
            render json: { error: result.errors_as_sentence, status: 422 }, status: :unprocessable_entity
          end
        end

        def destroy
          organization = Organization.find(params[:id])
          organization.destroy

          render json: {}, status: :ok
        end

        private

        def organization_params
          params.require(:organization).permit %i[name profile_image slug summary tag_line url]
        end
      end
    end
  end
end
