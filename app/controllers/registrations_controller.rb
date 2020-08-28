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
    not_authorized unless SiteConfig.allow_email_password_registration

    build_resource(sign_up_params)
    resource.saw_onboarding = false
    resource.editor_version = "v2"
    resource.save if resource.email.present?
    yield resource if block_given?
    if resource.persisted?
      redirect_to "/confirm-email?email=#{resource.email}"
    else
      render action: "by_email"
    end
  end
end
