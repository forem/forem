module Admin
  module Settings
    class SMTPSettingsController < Admin::Settings::BaseController
      def authorization_resource
        ::Settings::SMTP
      end
    end
  end
end
