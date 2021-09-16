module Api
  module V0
    class InstancesController < ApiController
      before_action :set_no_cache_header

      def show
        render json: {
          context: ApplicationConfig["FOREM_CONTEXT"],
          cover_image_url: Settings::General.main_social_image,
          description: Settings::Community.community_description,
          display_in_directory: Settings::UserExperience.display_in_directory,
          logo_image_url: Settings::General.logo_png,
          name: Settings::Community.community_name,
          registered_users_count: User.registered.estimated_count,
          tagline: Settings::Community.tagline,
          version: "edge.#{Time.now.utc.strftime('%Y%m%d')}.0",
          visibility: visibility
        }, status: :ok
      end

      private

      def visibility
        return "pending" if Settings::General.waiting_on_first_user

        Settings::UserExperience.public ? "public" : "private"
      end
    end
  end
end
