module Admin
  module Settings
    class CampaignsController < Admin::Settings::BaseController
      private

      def authorization_resource
        ::Settings::Campaign
      end
    end
  end
end
