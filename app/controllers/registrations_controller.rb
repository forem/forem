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
    raise unless SiteConfig.allow_email_password_registration

    build_resource(sign_up_params)
    resource.saw_onboarding = false
    resource.editor_version = "v2"
    resource.save
    yield resource if block_given?
    if resource.persisted?
      redirect_to "/confirm-email?email=#{resource.email}"
    else
      # # Todo: complete the flow
      # clean_up_passwords resource
      # set_minimum_password_length
      @hey="hey"
      render action: "by_email"
      # respond_with resource, location: "/enter?state=beta_email_signup"
    end
  end
end
