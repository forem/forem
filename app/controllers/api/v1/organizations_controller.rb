module Api
  module V1
    class OrganizationsController < ApiController
      include Api::OrganizationsController
      before_action :find_organization, only: %i[users listings articles]
      before_action :authenticate!, only: %i[create update destroy]
      before_action :authorize_admin, only: %i[update]
      before_action :authorize_super_admin, only: %i[create destroy]
      after_action :verify_authorized, only: %i[create update destroy]

      INDEX_ATTRIBUTES_FOR_SERIALIZATION = %i[
        id name profile_image slug summary tag_line url
      ].freeze

      SHOW_ATTRIBUTES_FOR_SERIALIZATION = %i[
        id username name summary twitter_username github_username url
        location created_at profile_image slug tech_stack tag_line story
      ].freeze

      def index
        per_page = (params[:per_page] || 30).to_i
        num = [per_page, per_page_max].min
        page = params[:page] || 1

        organizations = Organization.select(INDEX_ATTRIBUTES_FOR_SERIALIZATION).page(page).per(num)

        render json: organizations
      end

      def show
        # This is less RESTful than having a show action that would always assume an id
        # unless given e.g. a query parameter specifying a different lookup key.
        # The by-username lookup is the current default behavior, this approach
        # keeps it intact. Conventionally, the lookup would default to id-based if we keep both.
        finder = Organization.select(SHOW_ATTRIBUTES_FOR_SERIALIZATION)
        @organization = finder.find_by(id: params[:id_or_slug]) || finder.find_by(slug: params[:id_or_slug])
        raise ActiveRecord::RecordNotFound unless @organization

        render :show
      rescue ArgumentError => e
        render json: { error: e }, status: :unprocessable_entity
      end

      def create
        organization = Organization.new params_for_create
        authorize organization
        if organization.save!
          render json: {
            id: organization.id,
            name: organization.name,
            profile_image: organization.profile_image_url,
            slug: organization.slug,
            summary: organization.summary,
            tag_line: organization.tag_line,
            url: organization.url
          }, status: :created
        else
          render json: { error: organization.errors_as_sentence, status: 422 }, status: :unprocessable_entity
        end
      rescue ArgumentError => e
        render json: { error: e }, status: :unprocessable_entity
      end

      def update
        set_organization
        @organization.assign_attributes(organization_params)
        if @organization.save
          render json: {
            id: @organization.id,
            name: @organization.name,
            profile_image: @organization.profile_image_url,
            slug: @organization.slug,
            summary: @organization.summary,
            tag_line: @organization.tag_line,
            url: @organization.url
          }
        else
          render json: { error: @organization.errors_as_sentence, status: 422 }, status: :unprocessable_entity
        end
      rescue ArgumentError => e
        render json: { error: e }, status: :unprocessable_entity
      end

      def destroy
        set_organization
        Organizations::DeleteWorker.perform_async(@organization.id, @user.id, false)

        render json: { message: "deletion scheduled for organization with ID #{@organization.id}", status: 200 }
      rescue ArgumentError => e
        render json: { error: e }, status: :unprocessable_entity
      end

      private

      def authorize_admin
        authorize Organization, :access?, policy_class: InternalPolicy
      end

      def organization_params
        params.require(:organization).permit(:id, :name, :profile_image, :slug, :summary, :tag_line, :url)
      end

      # Accepts either an image file or a remote url for an image in the :profile_image attribute
      def params_for_create
        image = params.dig(:organization, :profile_image)

        # If the user has given a url for the profile image, place it where it should be handled
        if image.is_a? String
          permitted_params = organization_params.to_h
          permitted_params.delete(:profile_image)
          permitted_params[:remote_profile_image_url] = Images::SafeRemoteProfileImageUrl.call(image)
        end
        permitted_params
      end

      def set_organization
        @organization = Organization.find_by(id: params[:id])
        not_found unless @organization
        authorize @organization
      end
    end
  end
end
