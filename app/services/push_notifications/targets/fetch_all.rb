module PushNotifications
  module Targets
    class FetchAll
      def self.call
        forem_bundle = PushNotificationTarget::FOREM_BUNDLE
        existing_platforms = PushNotificationTarget.where(app_bundle: forem_bundle).pluck(:platform)
        (PushNotificationTarget::FOREM_APP_PLATFORMS - existing_platforms).each do |platform|
          # Re-create the supported Forem apps if they're missing
          PushNotificationTarget.create(app_bundle: forem_bundle, platform: platform, active: true)
        end

        PushNotificationTarget.all
      end
    end
  end
end
