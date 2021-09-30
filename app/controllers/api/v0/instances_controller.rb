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
          version: release_version,
          visibility: visibility
        }, status: :ok
      end

      private

      def visibility
        return "pending" if Settings::General.waiting_on_first_user

        Settings::UserExperience.public ? "public" : "private"
      end

      def release_version
        File.read(Rails.root.join(".release-version"))

      # Accommodate the .release-version file not existing in the case where
      # this deployment is deployed from a checkout/snapshot of the code.
      rescue StandardError
        # Get the latest modified file in the app. We don't use git in case it's
        # being run from a snapshot of the code outside a git repo (for example:
        # https://github.com/forem/forem/archive/refs/heads/main.zip), but
        # instead we use the latest modified time ("mtime") from application
        # code.
        latest_mtime = Dir[Rails.root.join("{app,config,db,lib}/**/*")]
          .max_by { |filename| File.mtime(filename) }
          .then { |filename| File.mtime(filename) }

        "edge.#{latest_mtime.strftime('%Y%m%d')}.0"
      end
    end
  end
end
