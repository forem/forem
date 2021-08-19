module Admin
  module Settings
    class UserExperiencesController < Admin::Settings::BaseController
      private

      def authorization_resource
        ::Settings::UserExperience
      end
    end
  end
end
