module Api
  module V0
    class ProfileImagesController < ApiController
      before_action :set_cache_control_headers, only: %i[show]

      def show
        not_found unless profile_image_owner

        @profile_image_url = profile_image_owner.profile_image_url
      end

      private

      def profile_image_owner
        user || organization
      end

      def user
        @user ||= User.select(:id, :profile_image)
          .find_by(username: params[:username], registered: true)
      end

      def organization
        @organization ||= Organization.select(:id, :profile_image)
          .find_by(username: params[:username])
      end
    end
  end
end
