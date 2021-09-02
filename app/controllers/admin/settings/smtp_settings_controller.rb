module Admin
  module Settings
    class SMTPSettingsController < Admin::Settings::BaseController
      private

      def authorization_resource
        ::Settings::SMTP
      end
    end
  end
end
