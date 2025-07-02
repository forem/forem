class RegistrationsController < Devise::RegistrationsController
  prepend_before_action :require_no_authentication, only: []

  def new
    return redirect_to root_path(signin: "true") if user_signed_in?

    if URI(request.referer || "").host == URI(request.base_url).host
      store_location_for(:user, request.referer)
    end

    if RequestStore.store[:subforem_id] &&
        RequestStore.store[:root_subforem_id] &&
        RequestStore.store[:subforem_id] != RequestStore.store[:default_subforem_id] &&
        RequestStore.store[:subforem_id] != RequestStore.store[:root_subforem_id]
      subforem = Subforem.find_by(id: RequestStore.store[:root_subforem_id])
      return unless subforem

      return redirect_to URL.url("/enter?state=#{params[:state]}", subforem), allow_other_host: true, status: :moved_permanently
    end

    super
  end

  def create
    authorize(params, policy_class: RegistrationPolicy)

    unless recaptcha_verified?
      flash[:notice] = I18n.t("registrations_controller.error.recaptcha")
      return redirect_to new_user_registration_path(state: "email_signup")
    end

    build_devise_resource

    if resource.persisted?
      resource.set_initial_roles!

      if resource.creator?
        prepare_new_forem_instance
        sign_in(resource)
        redirect_to new_admin_creator_setting_path
      elsif ForemInstance.smtp_enabled?
        redirect_to confirm_email_path(email: resource.email)
      else
        sign_in(resource)
        redirect_to root_path
      end
    else
      render action: "by_email"
    end
  end

  private

  def prepare_new_forem_instance
    Settings::General.waiting_on_first_user = false
    Users::CreateMascotAccount.call
    Discover::RegisterWorker.perform_async # Register Forem instance on https://discover.forem.com
  end

  def recaptcha_verified?
    if ReCaptcha::CheckRegistrationEnabled.call
      recaptcha_params = { secret_key: Settings::Authentication.recaptcha_secret_key }
      params["g-recaptcha-response"] && verify_recaptcha(recaptcha_params)
    else
      true
    end
  end

  def check_allowed_email(resource)
    domain = resource.email.split("@").last
    return true if Settings::Authentication.acceptable_domain?(domain: domain)

    resource.email = nil
    # Alright, this error message isn't quite correct.  Is the email
    # from a blocked domain?  Or an explicitly allowed domain.  I
    # think this is enough.
    resource.errors.add(:email, I18n.t("registrations_controller.error.domain"))
  end

  def build_devise_resource
    build_resource(sign_up_params)
    resource.registered_at = Time.current
    resource.build_setting(editor_version: "v2")
    resource.profile_image = Images::ProfileImageGenerator.call if resource.profile_image.blank?
    if Settings::General.waiting_on_first_user
      resource.password_confirmation = resource.password
    end
    check_allowed_email(resource) if resource.email.present?
    resource.onboarding_subforem_id = RequestStore.store[:subforem_id] if RequestStore.store[:subforem_id].present?
    resource.save if resource.email.present?
  end
end
