module Admin
  module Settings
    class UserExperiencesController < Admin::Settings::BaseController
      def authorization_resource
        ::Settings::UserExperience
      end
    end
  end
end
