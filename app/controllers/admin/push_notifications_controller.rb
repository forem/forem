module Admin
  class PushNotificationsController < Admin::ApplicationController
    layout "admin"

    def index
      @pn_targets = PushNotificationTarget.all_targets
    end

    private

    def authorize_admin
      authorize PushNotificationTarget, :access?, policy_class: InternalPolicy
    end
  end
end
