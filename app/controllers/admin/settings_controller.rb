module Admin
  # This controller is solely responsible for rendering the settings page at
  # /admin/customization/config. The actual updates get handled by the settings
  # controllers in the Admin::Settings namespace.
  class SettingsController < Admin::ApplicationController
    # NOTE: The "show" action uses a lot of partials, this makes it easier to
    # reference them.
    prepend_view_path("app/views/admin/settings")

    layout "admin"

    def show
      @confirmation_text =
        "My username is @#{current_user.username} and this action is 100% safe and appropriate."
    end

    private

    # We need to override this method from Admin::ApplicationController since
    # there is no resource to authorize.
    def authorization_resource; end
  end
end
