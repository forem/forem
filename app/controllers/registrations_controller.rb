class RegistrationsController < Devise::RegistrationsController
  prepend_before_action :require_no_authentication, only: []

  def new
    @registered_users_count = User.registered.estimated_count

    if user_signed_in?
      redirect_to dashboard_path
    else
      super
    end
  end
end
