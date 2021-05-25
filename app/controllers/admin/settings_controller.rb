module Admin
  class SettingsController < Admin::ApplicationController
    layout "admin"

    def show
      @confirmation_text =
        "My username is @#{current_user.username} and this action is 100% safe and appropriate."
    end

    private

    def authorization_resource
      nil
    end
  end
end
