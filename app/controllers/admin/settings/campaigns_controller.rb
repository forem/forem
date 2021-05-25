module Admin
  module Settings
    class CampaignsController < Admin::Settings::BaseController
      private

      def upsert_config(configs)
        ::Campaigns::SettingsUpsert.call(configs).errors
      end
    end
  end
end
