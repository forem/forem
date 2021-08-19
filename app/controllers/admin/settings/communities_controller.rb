module Admin
  module Settings
    class CommunitiesController < Admin::Settings::BaseController
      private

      def authorization_resource
        ::Settings::Community
      end
    end
  end
end
