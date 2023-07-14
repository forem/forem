module Api
  module V1
    class OrganizationsController < ApiController
      include Api::OrganizationsController
      before_action :authenticate!, only: %i[create update destroy]
      before_action :authorize_admin, only: %i[create update]
      before_action :authorize_super_admin, only: %i[destroy]
      after_action :verify_authorized, only: %i[create update destroy]
      before_action :find_organization, only: %i[users listings articles]

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
        lookup_key = params[:id_or_slug]
        @organization =
          if numbery?(lookup_key)
            Organization.find(params[:id_or_slug].to_i)
          else
            Organization.find_by!(username: params[:id_or_slug])
          end

        render :show
      rescue ArgumentError => e
        render json: { error: e }, status: :unprocessable_entity
      end

      def update
        @user = current_user
        set_organization
        @organization.assign_attributes(organization_params)
        if @organization.save
          render json: {
            id: @organization.id,
            name: @organization.name,
            profile_image: @organization.profile_image,
            slug: @organization.slug,
            summary: @organization.summary,
            tag_line: @organization.tag_line,
            url: @organization.url
          }, status: :ok
        else
          render json: { error: @organization.errors_as_sentence, status: 422 }, status: :unprocessable_entity
        end
      rescue ArgumentError => e
        render json: { error: e }, status: :unprocessable_entity
      end

      def destroy
        organization = Organization.find(params[:id])
        authorize organization
        organization.destroy

        render json: {}, status: :ok
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

      def numbery?(value)
        (value.is_a? Integer) || (value.to_i.to_s == value.to_s)
      end

      def set_organization
        @organization = Organization.find_by(id: params[:id])
        not_found unless @organization
        authorize @organization
      end
    end
  end
end
