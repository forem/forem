module Api
  module V0
    class ForemDirectoriesController < ApiController
      def index
        render json: {
          cover_image_url: Settings::General.main_social_image,
          description: Settings::Community.community_description,
          logo_image_url: Settings::General.logo_png,
          name: Settings::Community.community_name,
          tagline: Settings::Community.tagline,
          version: "edge.#{Time.current.strftime('%Y%m%d')}.0",
          visibility: visibility
        }.to_json,
               status: :ok
      end

      private

      def visibility
        # TODO(ecosystem team) - add logic to determine if a Forem instance is suspended
        return "pending" if Settings::General.waiting_on_first_user

        Settings::UserExperience.public ? "public" : "private"
      end
    end
  end
end
