class RegistrationsController < Devise::RegistrationsController
  prepend_before_action :require_no_authentication, only: []

  def new
    if user_signed_in?
      redirect_to dashboard_path
    else
      super
    end
  end

  def create
    build_resource(sign_up_params)
    resource.saw_onboarding = false
    resource.editor_version = "v2"
    resource.save
    yield resource if block_given?
    if resource.persisted?
      redirect_to "/confirm-email"
    else
      # Todo: complete the flow
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end
end
